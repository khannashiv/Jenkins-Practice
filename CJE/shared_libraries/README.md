**Concept of Shared Library**

Official Docs :
- [**Jenkins Shared Libraries**](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)
- [**Script Approval**](https://www.jenkins.io/doc/book/managing/script-approval/)
- [**GitHub API Global Lib Example**](https://github.com/darinpope/github-api-global-lib/blob/main/vars/helloWorld.groovy)
- [**YouTube Tutorial**](https://www.youtube.com/watch?v=Wj-weFEsTb0)


  **Theory**

  - Shared library is a collection of Groovy scripts that define reusable functions (steps) for your Jenkins pipeline.
  - This function encapsulates common tasks, making your pipeline more concise and readable.
  - Imagine a 3-step process where we have to start with building an app, running unit tests & deploying it.
  - Now say you have many jobs (across different projects), each doing similar tasks without shared library we will go ahead & copy the code to the Jenkins files where we have to implement above 3 steps again & again.
  - Here we are eventually duplicating the code across multiple Jenkins pipelines which may lead to inconsistency where changes in 1 Jenkins file might not be reflected in other Jenkins files.
  - Finally this makes it difficult (increasing complexity) to manage the same Jenkins file across multiple projects.
  - As pipeline grows managing scattered code becomes cumbersome. Shared library solves this problem by providing a central location to store reusable Groovy scripts that can be incorporated into your Jenkins file.
  - So this promotes "DRY" principles where code is written once & re-used across jobs. You will get consistency where you can go ahead & update your code/pipeline changes at 1 place which will automatically update the same code across multiple Jenkins pipelines saving time, removing redundant work & provide better readability (maintainability).
  - Central location can be anything where code related to shared library is stored, in most cases it's a Git repository


  **STEPS TO IMPLEMENT SHARED LIBRARY**

  - Create an SCM repository for shared code. (explicitly for shared library code.). This keeps it organized & easy to track.
  - Under Jenkins, we will configure global pipeline library here we will provide details like: library name, how Jenkins can
    retrieve the information which is stored under git repository.
  - Then we can write Groovy script defining your reusable function or method within the shared library in the repository. We can think it as building block of the pipeline.
  - Finally within Jenkins file, we will make use of @Library directive (annotation) to load the shared library and call your custom step within your pipeline stage making code more concise & maintainable.

  **Shared library repository structure**

    (root)
    +- src                     # Groovy source files
    |   +- org
    |       +- foo
    |           +- Bar.groovy  # for org.foo.Bar class
    +- vars
    |   +- foo.groovy          # for global 'foo' variable
    |   +- foo.txt             # help for 'foo' variable
    +- resources               # resource files (external libraries only)
    |   +- org
    |       +- foo
    |           +- bar.json    # static helper data for org.foo.Bar

  - While all the directories are not mandatory but it helps you to organize your code efficiently.
  - src folder is optional directory but it follows standard java project structure & it gets added to classpath when executing jenkins pipeline.
  - It is generally recommended to avoid using shared libraries as it is meant for compiled code.

  - Next we have var directory which is mandatory one so this where you will define your re-usable functions or steps for your pipeline. Within the vars directory no sub-folders are allowed, you need to keep things organized within the root of vars folder.

  - For naming convention, we use camel case for the file-name where say we have file called as : welcomeMessage.groovy (For this file w is in lowercase & M is in uppercase) under the root of vars folder. Optionally we can also include matching file with .txt extension i.e. (welcomeMessage.txt) for documentation purpose, jenkins can process this .txt file through the system's configured markup formatter.

  - Finally we can have resources directory which is again optional but resources directory allows the libraryResource step to be used from an external library to load associated non-Groovy files. Currently this feature is not supported for internal libraries.

  - For further demos we are going to re-factor our jenkins file and we will creating a new branch by the name of feature/advanced from feature/slack-notification.

  - Here in the new branch we will be commenting out most of the stages which we are not going to use going forward.

  **--Practical Implementation--**

  - In order to configure shared libraries the very first step is to configure Global Trusted Pipeline Libraries. For this we need to go to Manage Jenkins >> System >> Look for : Global Trusted Pipeline Libraries  >> Add more details here such as:

    - Name of the library : my-shared-library
    - Default version: main
    - Allow default version to be overridden, Include @Library changes in job recent changes --> These are checked in my case.
    - Retrieval method: Modern SCM
    - Further we have to add details of Git repository.For this we need to create a new repository first as shown below.
    - New repo created for this demo: [**GitHub Shared Library Repo**](https://github.com/khannashiv/gitea-shared-library-jenkins) --> In this repo I have vars folder holding 1 file by the name of : slackNotification.groovy

**--Practical implementation completed here--**

    - Theory : Global Trusted Pipeline Libraries & Global Untrusted Pipeline Libraries ....

        - Global Untrusted Pipeline Libraries : Shareable libraries available to any Pipeline jobs running on this system. These libraries will be untrusted, meaning they run with "sandbox" restrictions (requires admin approval) and cannot use @Grab.

        - Global Trusted Pipeline Libraries : Shareable libraries available to any Pipeline jobs running on this system. These libraries will be trusted, meaning they run without "sandbox" restrictions (does not require admin approval) and may use @Grab.

        - Load implicitly: Whenever we check this, all the pipelines that we have within Jenkins can load this library without
            needing to request it via @Library. We will clearly state which pipeline is going to use this (i.e.slackNotification.groovy) specific library. (Don't check this box)

        - Allow default version to be overridden: If you have multiple versions like multiple branches with different set of libraries, we can override them using @some-version in @Library annotation. (Check this box)

        - Include @Library changes in job recent changes: To include changes in the upcoming builds if changes made to library code. (Check this box as well)

    - So whatever library we have created i.e. slackNotification.groovy will fall under trusted one since we are aware of the fact it doesn't contain any vulnerability & we can easily use them as I have created this library so we can configure them under Global Trusted Pipeline Libraries. But at the same time we do have some more libraries which are available on internet but those are developed by some other developers so those are like untrusted library since they may contain malicious code. So these library can be configured as under : Global Untrusted Pipeline Libraries. So this means Jenkins is going to run under sandbox environment

    - Groovy Sandbox

        - [**Script Approval**](https://www.jenkins.io/doc/book/managing/script-approval/)
        - [**Groovy Sandbox**](https://github.com/jenkinsci/groovy-sandbox)

    - What is @Grab ?

    - @Grab : Can only be used within Global Trusted Pipeline Libraries since we don't have sandbox restrictions. It is possible to use third-party Java libraries, typically found in Maven Central, from trusted library code using the @Grab annotation.

-----------------------------

**Demo: Loading the Shared Library in pipeline**

- In this demo, we have updated Jenkins file to make use of shared library such that at the very top of pipeline we have made use of : @Library('my-shared-library') _

- Under post {always {}} replace the name of the invoked/calling function to slackNotification() i.e. the Groovy file present under GitHub whose path is : gitea-shared-library-jenkins/vars/slackNotification.groovy where .groovy will get replaced with parentheses i.e. ()

- The last change that we have made is: under slackNotification.groovy file we have updated initial function name to slack_notification() to call() i.e. def call()

- Summary

| Initial function name | Final function name | Description |
|-----------------------|---------------------|-------------|
| def slack_notification() | def call() | File name i.e. slackNotification.groovy file present under vars folder of git repo. |
| slack_notification() | slackNotification() | Updated under Jenkinsfile under post >> always actions where we do function call/invoke. |

----------------------------------

**Demo: Create shared library for Trivy Scan Stage**

- So here we are going to create another Groovy file/script under vars folder of same repository i.e.
    [**GitHub Shared Library Repo**](https://github.com/khannashiv/gitea-shared-library-jenkins.git)

- So in this case we are going to create a new branch since earlier we have done testing on main branch in our last demo.

- Here we have created a new branch i.e. (feature/TrivyScan) from main branch.
    - git checkout -b feature/TrivyScan   # Creating a new branch.
    - git push origin feature/TrivyScan   # Publishing a new branch to git repo.

- After switching to new branch i.e. feature/TrivyScan, we will go ahead & add new file by the name of trivyScan.groovy.

- Under which we have copied the code from stage ('Trivy vulnerability Scanner') present in jenkins file ( i.e. my-demo-active-org/solar-system-migrate) which is related to shell script in the form of 2 functions one is def vulnerabilityScan(String imageTag) & other is def convertFormat().

- So under Jenkins file we have this value hardcoded i.e. khannashiv/solar-system:$GIT_COMMIT which we try to fetch dynamically under Groovy script so under Groovy script we are going to pass 1 parameter inside this function i.e. def vulnerabilityScan(String imageTag)

- NOTE: VERY IMPORTANT POINT TO REMEMBER

    - Groovy variable always follows string interpolation when called under shell script may be local/global/environment variable. For example i.e.

            def vulnerabilityScan(String imageName)

    - Groovy variable interpolation only works with double quotes (" " or """ """), not with single quotes (' ' or ''' ''').

- So whenever I have to call this variable under shell script it follows string interpolation i.e. ${imageName}

- Overall trivyScan.groovy file looks something like shown below.

```groovy
def vulnerabilityScan(String imageName) {

    sh """
        echo "Docker image is: ${imageName}"

        trivy image --severity HIGH,MEDIUM,LOW --exit-code 0 --quiet --format json --output trivy-image-high-medium-low-results.json ${imageName}

        trivy image --severity CRITICAL --exit-code 1 --quiet --format json --output trivy-image-critical-results.json ${imageName}
    """
}


def convertFormat() {

   sh '''
        echo "Converting Trivy JSON reports to HTML and JUnit XML..."

        trivy convert --format template \
            --template "@/usr/local/share/trivy/templates/html.tpl" \
            --output trivy-image-high-medium-low-results.html \
            trivy-image-high-medium-low-results.json

        trivy convert --format template \
            --template "@/usr/local/share/trivy/templates/html.tpl" \
            --output trivy-image-critical-results.html \
            trivy-image-critical-results.json

        trivy convert --format template \
            --template "@/usr/local/share/trivy/templates/junit.tpl" \
            --output trivy-image-critical-results.xml \
            trivy-image-critical-results.json

        trivy convert --format template \
            --template "@/usr/local/share/trivy/templates/junit.tpl" \
            --output trivy-image-high-medium-low-results.xml \
            trivy-image-high-medium-low-results.json
    '''
}
```


Memory Tip:

Context                                 Syntax              Example

- Groovy variable in shell script         ${var}              sh "echo ${imageName}"
- Shell variable in shell script          $var or ${var}      sh 'echo $PATH'
- env variable in shell script            ${env.VAR}          sh "echo ${env.BUILD_URL}"
- Literal ${...} in shell                 \${...}             sh 'echo \${SHELL_VAR}'

Groovy variables always follow string interpolation (${variable}) when referenced inside shell script blocks, regardless of whether they are:

- Local variables - def myVar = "value"
- Global/script variables - imageName = "myapp"
- Environment variables - ${env.BUILD_NUMBER}
- Parameters - ${params.branch}
- Current build properties - ${currentBuild.result}

Examples for each type:

```groovy
// Local variable
def localVar = "docker-image"
sh "echo Building ${localVar}"

// Script/Global variable (defined outside functions)
imageTag = "v1.0"
sh "docker tag app:latest app:${imageTag}"

// Environment variable
sh "echo Build URL: ${env.BUILD_URL}"

// Parameter (from Jenkins job parameters)
sh "echo Deploying to: ${params.environment}"

// Current build properties
sh "echo Build result: ${currentBuild.currentResult}"

// Complex expression
sh "echo Short commit: ${env.GIT_COMMIT.substring(0, 7)}"
```


-------------------------------------------------------------------------------------------------

**Demo: Load Trivy Scan library in Jenkins pipeline**

- In this case make sure we have this option checked i.e. Allow default version to be overridden
- Update Jenkins file to make use of @Library annotation as : @Library('my-shared-library@feature/TrivyScan') _
- where : feature/TrivyScan --> This is a feature branch
- In this case we won't use directly Groovy file name under Jenkins file stage ('Trivy vulnerability Scanner') because we don't have call method under Groovy file instead we have 2 different methods with unique names.
- Hence we will make use of groovy_file_name.method_name("Passing the value of input parameter if function/method requires it.") as shown below.
    - trivyScan.vulnerabilityScan("khannashiv/solar-system:${env.GIT_COMMIT}")
    - trivyScan.convertFormat()
- So this is how we are going to load shared library.

- NOTE :  VERY IMPORTANT
    - Declarative Pipeline does not allow method calls on objects outside "script" blocks.The method calls above would need to be put inside a script directive:

- [**Reference Docs**](https://www.jenkins.io/doc/book/pipeline/shared-libraries/#retrieval-method)
    - In the above documentation search for following topic i.e. "Defining global variables"

- Error 1 :

```
org.codehaus.groovy.control.MultipleCompilationErrorsException: startup failed:

WorkflowScript: 258: Method calls on objects not allowed outside "script" blocks. @ line 258, column 6.

                    trivyScan.convertFormat()

        ^


WorkflowScript: 258: Missing required parameter: "message" @ line 258, column 6.

                    trivyScan.convertFormat()
```

- After fixing the error this is how the final stage looks like i.e.

    - Fix1
        script{
                            trivyScan.vulnerabilityScan("khannashiv/solar-system:${env.GIT_COMMIT}")
        }
    - Fix 2
        script {
                echo "Converting Trivy JSON reports to HTML and JUnit XML..."
                trivyScan.convertFormat()
        }

    - Final complete working stage.

```groovy
stage ('Trivy vulnerability Scanner'){
    steps{
        script{
            trivyScan.vulnerabilityScan("khannashiv/solar-system:${env.GIT_COMMIT}")
        }
    }

    post {
        always {
            script {
                echo "Converting Trivy JSON reports to HTML and JUnit XML..."
                trivyScan.convertFormat()
            }
            
            // Picking publishHTML step from Trivy scan for low and medium vulns
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'trivy-image-high-medium-low-results.html', reportName: 'Trivy-low-medium-HTML-Report', reportTitles: '', useWrapperFileDirectly: true])

            // Picking publishHTML step from Trivy scan for high and critical vulns
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'trivy-image-critical-results.html', reportName: 'Trivy-high-critical-HTML-Report', reportTitles: '', useWrapperFileDirectly: true])

        }
    }
}
```

```

**Q:** Why we have not received failure notification on Slack when we see failure in pipeline with following error?

```
[Gitea] Notified
org.codehaus.groovy.control.MultipleCompilationErrorsException: startup failed:
WorkflowScript: 262: Method calls on objects not allowed outside "script" blocks. @ line 262, column 6.

                    trivyScan.convertFormat()

        ^
WorkflowScript: 262: Missing required parameter: "message" @ line 262, column 6.

                    trivyScan.convertFormat()

        ^

2 errors

    at org.codehaus.groovy.control.ErrorCollector.failIfErrors(ErrorCollector.java:309)
    at org.codehaus.groovy.control.CompilationUnit.applyToPrimaryClassNodes(CompilationUnit.java:1107)
    at org.codehaus.groovy.control.CompilationUnit.doPhaseOperation(CompilationUnit.java:624)
```

**A:**

The reason your Slack notification isn't triggering is because the entire pipeline fails during compilation (before any stages even run), due to the syntax error at line 262. The compilation happens before execution, so if there's a syntax error, the pipeline never runs and the post block for the entire pipeline (with your Slack notification) never executes.

```


```

**Q:** Error when executing always post condition:

```
org.jenkinsci.plugins.scriptsecurity.sandbox.RejectedAccessException: Scripts not permitted to use method groovy.lang.GroovyObject invokeMethod java.lang.String java.lang.Object (org.jenkinsci.plugins.workflow.cps.CpsClosure2 slackNotification)
```

**A:** (No solution provided in the text.)

```

----------------------------------- 

**Demo: Shared Library - Library Resources**

- Library resources can store non groovy static assets such as: such as shell script, YAML files in a resources directory. This can be referred & used in shared library.

- Let's understand where & how to use in our use case ?

- If we go back to shared library repository we have worked on trivyScan.groovy script . If we look at the script we are hardcoding the commands as we can see we have 2 Trivy commands of different Severity Level but requirement gets chnaged we may have different set of configuration: one we must give developers an option to change docker image & to have different severities of exit codes. If we go with hardcoded approach we may need to have multiple Trivy image commands for each & every configuration which is not at all efficient.

- So how do we eliminate this ?

- We will go ahead & create a static shell script which is going to run Trivy Image command but we can customize other options as well. So the very first step is we will go ahead & create resources folder under the same repo where we have vars folder, parallel to that we will go ahead & create resources folder >> under that let's create scripts folder >> under this we will go ahead & create file by the name of trivy.sh

- Following is my trivy.sh file present under resources/scripts folder i.e.

```bash
#!/bin/bash

echo "1st positional arguments related to severity: $1"
echo "2nd positional argument related to exit-code: $2"
echo "3rd positional argument docker image: $3"

# Generate timestamp for unique filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="trivy-image-${TIMESTAMP}.json"

trivy image \
    --severity "$1" \
    --exit-code "$2" \
    --format json \
    --output "$OUTPUT_FILE" \
    "$3"

echo "Results saved to: $OUTPUT_FILE"
```

- How to use this shell script in the shared library ?

- So we can create a new groovy script by the name of trivyScanScript.groovy under vars folder.
- Let's go ahead & create a new method by the name of vulnerabilityScan where we are going to pass path to shell script i.e.
    trivy.sh something like shown below.

    def vulnerabilityScan() {
        sh "./trivy.sh"   
    }

- Further we have couple of positional arguments that we have to make use in the above function since actual shell script i.e. trivy.sh make use of 3 positional arguments so we will make use of map as a data type which we are going to pass to the above 
function as parameter/argument.

- Map config = [:] --> This means .

        -- Map is datatype
        -- config is a variable name
        -- [:] creates an empty Map (dictionary/hash), not a List
    
    def myFunction(Map config = [:]) {
        // If no argument is passed, config defaults to empty map
        // If argument is passed, config contains that map
    }

- Groovy convention - Variables typically start lowercase hence c in config is written in lowercase.

- In shell script we would have called positional args something like : sh "./trivy.sh $1 $2 $3" but in this case we may call it as : sh "./trivy.sh ${config.severity} ${config.exit-code} ${config.imageName}" 

- To load the file locally in pwd, we are writting loadScript(name: trivy.sh) but we need to create a loadScript.groovy file under the vars directory.

- Where loadScript.groovy file looks something like shown below.

```groovy
def call(Map config = [:]) {
    def scriptData = libraryResource "scripts/${config.name}"
    writeFile file: "${config.name}", text: scriptData
    sh "chmod +x ./${config.name}"
}
```

- In the above function we have something called as : scriptData which is loaded as string. In the above function we are using  scriptData as a variable to load Trivy shell script present under resources/scripts using libraryResource (which will look into resources folder at the root of repo from there it will navigate to scripts folder & within that scripts folder it will try to fetch config.name) syntax.

- Why are we using config.name everywhere in the above function the reason for it, if we look at trivyScanScript.groovy we have loadScript function which is using name as one of the parameter which directly points to shell script.

- We are using writeFile to asve the file in workspace of Jenkins.

- Since the file is loaded as string in a plain format, we need to make file executable hence we are using chmod command.

- NOTE : 

    - [**Docs**](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)
    - A resources directory allows the libraryResource step to be used from an external library to load associated non-Groovy files. Currently this feature is not supported for internal libraries.
    - The file is loaded as a string, suitable for passing to certain APIs or saving to a workspace using writeFile.

Summary ....

- First of all we are going to create a file by the name of trivyScanScript.groovy
- Which calls load script library to load & execute trivy.sh file, it also has an ability to customize image name, severity & exit codes.
- Next we must have loadScript.groovy file as well, since this is again a separate library which is going to provide generic way to load any scripts from the resources/scripts directory.
- It loads & prepare Trivy.sh script from resources/ directory basically it's going to write the file onto the workspace & make file executable.
- Finally actual execution happens at Trivy.sh script which performs vulnerability scan on provided Docker image, severity, exit-codes.


Error 1 .

```
org.codehaus.groovy.control.MultipleCompilationErrorsException: startup failed:

WorkflowScript: 251: illegal colon after argument expression;

   solution: a complex label expression before a colon must be parenthesized @ line 251, column 72.

   can(severity: "LOW", exit-code: "0", ima

                         ^
1 error

    at org.codehaus.groovy.control.ErrorCollector.failIfErrors(ErrorCollector.java:309)
    at org.codehaus.groovy.control.ErrorCollector.addFatalError(ErrorCollector.java:149)
```

Solution :

```
trivyScanScript.updateVulnerabilityScan(exit-code: "0")  // Hyphen causes parsing issue

trivyScanScript.updateVulnerabilityScan(severity: "LOW", exitCode: "0", imageName: "...")
```

Initially : exit-code: "0" (was causing issue.)
Finally   : exitCode: "0"  (fixed it.)



Error 2 : groovy.lang.MissingPropertyException: No such property: trivy for class: trivyScanScript

Sol 2 : Updated vars/trivyScanScript.groovy file where I have added quotes: trivy.sh → 'trivy.sh' mentioned under loadScript().

```groovy
def updateVulnerabilityScan(Map config = [:]) {
    loadScript(name: 'trivy.sh')
    sh "./trivy.sh ${config.severity} ${config.exit-code} ${config.imageName}"
}
```

Error 3 :

```
chmod +x ./trivy.sh— Shell Script<1s
+ chmod +x ./trivy.sh
groovy.lang.MissingPropertyException: No such property: code for class: trivyScanScript
```

Solution :

Updated from ${config.exit-code} to ${config.exitCode} & updated function looks like as shown below i.e. /vars/trivyScanScript.groovy

```groovy
def updateVulnerabilityScan(Map config = [:]) {
    loadScript(name: 'trivy.sh')
    sh "./trivy.sh ${config.severity} ${config.exitCode} ${config.imageName}"
}
```
