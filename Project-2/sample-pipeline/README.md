## A simple jenkins pipeline to verify if the docker agent configuration is working as expected.

<!-- In this example 

  agent {
    docker { image 'rabbitmq:4.1-management' }
  } 

-- pipeline: Declares the start of a Jenkins Declarative Pipeline.
-- agent: Specifies where and how the pipeline or stage should run.
-- docker { image 'rabbitmq:4.1-management' }:
-- Jenkins will run the pipeline inside a Docker container.

The container will be based on the rabbitmq:4.1-management image, which is a RabbitMQ image that includes the management plugin (providing a web UI and HTTP API).

Ques : How Jenkins knows about the docker image ?
Sol  : Jenkins uses Docker installed on the build agent (the machine running the job).Following are the steps that will come into existence .

    -- Docker must be installed on the Jenkins agent where the job is running.
    -- Jenkins uses Docker installed on the build agent (the machine running the job). When Jenkins sees, docker { image 'rabbitmq:4.1-management' } it runs the equivalent of: docker pull rabbitmq:4.1-management i.e. to fetch the image from Docker Hub (the default public Docker registry), if it's not already present locally.
    -- Then, Jenkins starts a container from that image and runs the pipeline steps inside it.

Ques : How does Jenkins gets to know that I have to pull docker image from docker hub ?
Sol  : 
    -- Here we are providing an unqualified image name — i.e., not specifying any registry URL (like myregistry.com/rabbitmq).
        for example : docker { image 'rabbitmq:4.1-management' }
    -- Behind the scenes, Docker (not Jenkins directly) does this: Sees that rabbitmq:4.1-management has no registry prefix.
    -- Automatically assumes the registry is: https://registry-1.docker.io/ which is the Docker Hub API endpoint.
    -- Pulls the image from there using Docker's built-in logic.
    -- Jenkins simply uses the Docker CLI (via the docker pipeline syntax) on the agent.
    -- So it inherits Docker’s default behavior, including pulling from Docker Hub unless told otherwise.
  -->