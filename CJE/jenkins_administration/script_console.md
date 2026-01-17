# Jenkins Script Console

## Overview

The Jenkins Script Console is a powerful administrative tool that allows you to execute arbitrary Groovy scripts directly on the Jenkins controller or connected agents. This feature requires administrator permissions and is essential for tasks such as automation, diagnostics, troubleshooting, and advanced configuration management.

## Accessing the Script Console

To access the Script Console:

- Navigate to **Manage Jenkins** > **Script Console**.
- Alternatively, go to **Manage Jenkins** > **Nodes** > **Built-in Node** > **Script Console**.

## Useful Scripts

### Getting Jenkins Version

This script retrieves and prints the current Jenkins version.

```groovy
import jenkins.model.Jenkins

def jenkinsVersion = Jenkins.instance.version
println "Jenkins Version: ${jenkinsVersion}"
```

### Jenkins Statistics

This script generates high-level statistics for your Jenkins instance, including counts of organizations, projects, jobs, builds, users, pull requests, and tag releases. It provides insights into the overall health and usage of your Jenkins setup.

```groovy
/*
    Copyright (c) 2015-2024 Sam Gleske - https://github.com/samrocketman/jenkins-script-console-scripts

    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
    the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*
   This script generates high level Jenkins statistics for Jenkins instances
   using Jervis.
 */

import com.cloudbees.hudson.plugins.folder.Folder
import groovy.transform.Field
import hudson.model.Job
import hudson.model.User
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject

import jenkins.plugins.git.GitTagSCMHead
import org.jenkinsci.plugins.github_branch_source.PullRequestSCMHead
import org.jenkinsci.plugins.workflow.multibranch.BranchJobProperty


//globally scoped vars
j = Jenkins.instance
@Field HashMap count_by_type = [:]
count = j.getAllItems(Job.class).size()
jobs_with_builds = j.getAllItems(Job.class)*.getNextBuildNumber().findAll { it > 1 }.size()
global_total_builds = j.getAllItems(Job.class)*.getNextBuildNumber().sum { ((int) it) - 1 }
j.getAllItems().each { i ->
    count_by_type[i.class.simpleName.toString()] = (count_by_type[i.class.simpleName.toString()])? count_by_type[i.class.simpleName.toString()]+1 : 1
}

List known_users = User.getAll()*.id
organizations = j.getAllItems(Folder.class).findAll { !(it.name in known_users) }.size()
projects = j.getAllItems(WorkflowMultiBranchProject.class).size()
total_users = User.getAll().size()

total_pull_requests = j.getAllItems(WorkflowMultiBranchProject.class)*.getAllItems(Job.class).flatten().findAll {
    it.getProperty(BranchJobProperty)?.branch?.head in PullRequestSCMHead
}*.getNextBuildNumber().sum {
    ((int) it) - 1
}

total_tag_releases = j.getAllItems(WorkflowMultiBranchProject.class)*.getAllItems(Job.class).flatten().findAll {
    it.getProperty(BranchJobProperty)?.branch?.head in GitTagSCMHead
}*.getNextBuildNumber().sum {
    ((int) it) - 1
}

//display the information
println "Number of GitHub Organizations: ${organizations}"
println "Number of GitHub Projects: ${projects}"
println "Number of Jenkins jobs: ${count}"
println "Jobs with more than one build: ${jobs_with_builds}"
println "Number of users: ${total_users}"
println "Global total number of builds: ${global_total_builds}"
println "Global total number of pull requests executed: ${total_pull_requests}"
println "Global total number of tag releases executed: ${total_tag_releases}"
println "Count of projects by type."
count_by_type.each {
    println "  ${it.key}: ${it.value}"
}
//null because we don't want a return value in the Script Console
null
```

### Retrieving Job Details

This script iterates through all jobs in Jenkins and prints detailed information for each, including name, URL, last build number, and class type. Useful for auditing or reporting.

```groovy
import jenkins.model.Jenkins

def jobs = Jenkins.instance.getAllItems()

jobs.each { job ->
    println "##########################################"
    println "Job Full Name: ${job.fullName}"
    println "Job Name: ${job.name}"
    println "Job URL: ${job.absoluteUrl}"
    println "Last Build #: ${job.lastBuild?.number}"
    println "Job Class: ${job.getClass().name}"
    println "##########################################"
}
```

### Count Projects by Type

This script counts and displays the number of projects grouped by their type (e.g., FreeStyleProject, Pipeline). It helps in understanding the composition of your Jenkins instance.

```groovy
import hudson.model.Job
import jenkins.model.Jenkins

projects = [:]
Jenkins.instance.getAllItems(Job.class).each { Job j ->
    String jc = j.class.simpleName
    if(!(jc in projects)) {
        projects[jc] = 0
    }
    projects[jc]++
}
println "Count projects by type:"
projects.each { k, v ->
    println "    ${k}: ${v}"
}
null
```

## References

- [Jenkins Official Documentation: Script Console](https://www.jenkins.io/doc/book/managing/script-console/)
- [Jenkins Scripts Repository](https://github.com/jenkinsci/jenkins-scripts/tree/main/scriptler)
- [GitHub Topics: Groovy Scripts](https://github.com/topics/groovy-scripts?l=groovy&o=desc&s=stars)
- [Sam Gleske Jenkins Script Console Scripts](https://github.com/samrocketman/jenkins-script-console-scripts)
- [Groovy Language Documentation](https://groovy-lang.org/documentation.html)
- [Javadoc for Jenkins](https://javadoc.jenkins.io/)
- [Jenkins Developer Documentation](https://www.jenkins.io/doc/developer/)
- [KodeKloud Certified Jenkins Engineer Notes](https://notes.kodekloud.com/docs/Certified-Jenkins-Engineer/Jenkins-Administration-and-Monitoring-Part-1/Demo-Script-Console)


