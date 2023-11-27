from sonarqube import SonarQubeClient
import gitlab
from git import Repo
import os
import yaml
import shutil
from random import randrange


gitlab_groups = {
    "artifact": "9",
    "dev": "14",
    "dome": "10",
    "maid": "8",
    "minion": "7"
}

# gitlab_groups = {
#     "artifact": "9",
#     "dev": "14",
#     "dome": "10",
#     "maid": "8",
#     "minion": "7"
# }

EXCLUDED_PROJECTS = {
    "artifact": [],
    "dev": [],
    "dome": ["darkmoney","leakeddatabases","validmarket"],
    "maid": [],
    "minion": ["bankomat"]
}

FAILED_PROJECTS = {
    "artifact": [],
    "dev": [],
    "dome": [],
    "maid": [],
    "minion": []
}

GITLAB_CI_YML = ".gitlab-ci.yml"
SONAR_FILE = "sonar-project.properties"
BRANCH_NAME = "sonarqube-integration"
REPO_ROOT = f"{os.getenv('HOME')}/Gemini/temp_repos"

PROPS_TEMPLATE = "sonar.projectKey=<KEY>\n" \
                 "sonar.qualitygate.wait=true"

DUMMY_KEY = 'aaaaaaaaaaaaa'

DRY_RUN = False
GL_TOKEN = os.environ.get('GL_TOKEN')
SONAR_PASS = os.environ.get('SONAR_PASS')


# if DRY_RUN:
shutil.rmtree(REPO_ROOT)
os.mkdir(REPO_ROOT)

sonar = SonarQubeClient(sonarqube_url="https://sonar.regemini.io", username='admin', password=SONAR_PASS)

gl = gitlab.Gitlab(url='https://gitlab.regemini.com', private_token=GL_TOKEN)

# sonar.projects.create_project(project="ascarding", name="ascarding", visibility="private")

# groups = gl.groups.list()

total = 0
for group in gitlab_groups.items():

    group = gl.groups.get(group[1])
    projects = group.projects.list(get_all=True)

    print("Projects inside group {}:".format(group.name))
    for project in projects:
        if project.name in EXCLUDED_PROJECTS[group.name]:
            continue
        project = gl.projects.get(project.id)
        if project.archived:
            continue
        total += 1

        hasSonar = True;
        try:
            result = project.files.get(SONAR_FILE, project.default_branch)
            if type(result) is not gitlab.v4.objects.files.ProjectFile:
                # print("No sonar for {}: {}".format(group.name, project.name))
                hasSonar = False;

        except Exception as e:
            # print(f"No {SONAR_FILE} found for {group.name}/{project.name} - {project.web_url}")
            hasSonar = False;

        if hasSonar:
            continue

        hasGitlab = True;
        try:
            result = project.files.get(GITLAB_CI_YML, project.default_branch)
            if type(result) is not gitlab.v4.objects.files.ProjectFile:
                hasGitlab = False;
        except Exception as e:
            hasGitlab = False;

        if not hasGitlab:
            print(f"\tSKIPPING: Project not initiated - no {GITLAB_CI_YML} in {project.web_url}")
            continue

        print(f"\tProcessing: {project.name}, id: {project.id} - {project.web_url}")

        repo_path = os.path.join(REPO_ROOT, group.name, project.name)

        try:
            repo = Repo.clone_from(project.ssh_url_to_repo, repo_path)
            git = repo.git
            git.checkout("HEAD", b=BRANCH_NAME)  # create a new branch


            with open(os.path.join(repo_path, ".gitlab-ci.yml"), "r") as gitlab_ci_yaml:
                try:
                    gitlab_ci = yaml.safe_load(gitlab_ci_yaml)
                    if gitlab_ci["stages"][0] != 'scan':
                        gitlab_ci["stages"].insert(0, 'scan')
                    flat_list = [item for sublist in gitlab_ci["include"] for item in sublist]

                    proj_index = None
                    for i in range(0, len(gitlab_ci["include"])):
                        if "project" in gitlab_ci["include"][i].keys():
                            proj_index = i
                            break
                    if proj_index is not None:
                        if "file" in gitlab_ci["include"][proj_index].keys():
                            if not gitlab_ci["include"][proj_index]['file'][0].startswith('scan/'):
                                gitlab_ci["include"][proj_index]['file'].insert(0, 'scan/1.00-alpine/scan.yaml')
                        else:
                            gitlab_ci["include"][proj_index].insert(0, {'file': 'scan/1.00-alpine/scan.yaml'})
                    else:
                        gitlab_ci["include"].insert(0, {'project': "dev/gitlab-ci-library", 'ref': 'master',
                                                        'file': ['scan/1.00-alpine/scan.yaml']})

                    if 'sast' in gitlab_ci.keys():
                        gitlab_ci['sast'].update(
                            {'rules': [{'if': '$CI_SCHEDULE_SOURCE == "sonarqube"', 'when': 'never'}]})

                    if not DRY_RUN:
                        with open(os.path.join(repo_path, GITLAB_CI_YML), "w") as f:
                            data = yaml.dump(gitlab_ci, f, sort_keys=False, default_flow_style=False)
                            git.add(GITLAB_CI_YML)

                    if not DRY_RUN:
                        sonar_project_data = sonar.alm_integrations.import_gitlab_project(almSetting="Gemini",
                                                                                          gitlabProjectId=project.id)
                        project_key = sonar_project_data["project"]["key"]
                    else:
                        project_key = DUMMY_KEY

                    sonar_properties = open(os.path.join(repo_path, "sonar-project.properties"), "w")
                    sonar_properties.write(PROPS_TEMPLATE.replace("<KEY>", project_key))
                    sonar_properties.close()

                    if not DRY_RUN:
                        git.add("sonar-project.properties")
                        git.commit(message="Add SonarQube properties and pipeline")
                        print("Pushing changes to remote")
                        git.push(BRANCH_NAME, u="origin")

                        mr = project.mergerequests.create({'source_branch': BRANCH_NAME,
                                                           'target_branch': project.default_branch,
                                                           'title': 'On-board {} to SonarQube'.format(project.name),
                                                           'labels': ['Support', 'ToDo'],
                                                           'remove_source_branch': 'true',
                                                           'squash_on_merge': 'true',
                                                           'assignee_id' : 2,
                                                           'reviewer_ids': [2]})

                    else:
                        print("New {} for {}:".format(GITLAB_CI_YML, repo_path))
                        print(yaml.dump(gitlab_ci, sort_keys=False, default_flow_style=False))
                        print("\n")

                    if not DRY_RUN:
                        sched = project.pipelineschedules.create({
                            'ref': project.default_branch,
                            'description': 'SonarQube (weekly)',
                            'cron': '{} 2 * * 6'.format(randrange(59)),
                            'cron_timezone': 'UTC'
                        })
                        sched.variables.create(
                            {'key': 'CI_SCHEDULE_SOURCE', "variable_type": "env_var", 'value': 'sonarqube'})
                    else:
                        print("Adding pipeline schedule")

                    # print("\n================================================================\n\n")
                    # input("Press Enter to continue...")

                except yaml.YAMLError as exc:
                    print(exc)
                except Exception as exc:
                    print(exc)
        except Exception as e:
            print("Failed to process repo {}: {}".format(repo_path, e))
            FAILED_PROJECTS[group.name].append(project.name)
            # print("\n---------------\n\n")
            # input("Press Enter to continue...")
    #     break
    # break

print("Total projects: {}".format(total))
print("Failed projects:\n{}".format(FAILED_PROJECTS))
