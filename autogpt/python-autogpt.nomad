/* 
AutoGPT nomad job, intended for Arm64 (Raspberry Pi) cluster
Launches a Weaviate instance and a Python instance that runs the AutoGPT application
Designed for use with Nomad on a Raspberry Pi cluster
Bootstrap script syncs the latest master branch of AutoGPT from GitHub
Downloads and launches AutoGPT with GoTTY to allow access via a web browser
Persistent storage for Weaviate is stored in /media/cluster/common/autogpt/weaviate/data/ - Using docker.volumes.enabled = true
Persistent storage for AutoGPT is stored in a nomad mount titled "common" - in a folder called "autogpt"
Weaviate requires the deployment to be on the same host as the client, so this job is designed to be deployed to a single node
Matt Clare - Sunday April 30, 2023
*/

job "autogpt" {
  datacenters = ["dc1"]
  type        = "service"

group "python-weaviate-autogpt" {

 network {
      mode = "host"
      port http {
        to = 8080
      }
      port "weaviate" {
        static = 9090
        to = 8080
      }
    }

    volume "vol-common" {
      type      = "host"
      read_only = false
      source    = "common"
    }
	
    task "python-autogpt" {
      driver = "docker"

      volume_mount {
          volume      = "vol-common"
          destination = "/common"
          read_only   = false
      }
      
      config {
        #image = "python"
        image = "python:3.10-slim"
	      interactive = true
           ports  = ["http"]
        
        command = "sh"
	      args = ["-c", "/common/autogpt/autogpt-bootstrap.sh;"]

      }
      
env { 
        /* Bootstrap script writes most of following enviroment varialbes to /common/autogpt/autogpt.env
           New variables will have to be added to that script.
        */
        #API Keys
        GOOGLE_API_KEY=""
        CUSTOM_SEARCH_ENGINE_ID=""

        COMMON_DIR="/common/autogpt"

        #OpenAI stuff
        OPENAI_API_KEY=""
        /*ELEVENLABS_API_KEY=<your open-api-key>*/
        #SMART_LLM_MODEL="gpt-4" #optional
        SMART_LLM_MODEL="gpt-3.5-turbo" #optional
        FAST_LLM_MODEL="gpt-3.5-turbo" #optional
        EXECUTE_LOCAL_COMMANDS=true
        RESTRICT_TO_WORKSPACE=true
        TEMPERATURE=0.2
        FAST_TOKEN_LIMIT=4000
        SMART_TOKEN_LIMIT=8000
        IMAGE_PROVIDER=dalle
        IMAGE_SIZE=256

        #Plugins
        ALLOWLISTED_PLUGINS="AutoGPTNewsSearch,AutoGPTRandomValues,AutoGPTWikipediaSearch"
        DENYLISTED_PLUGINS="AutoGPTBingSearch,AutoGPTEmailPlugin,AutoGPTSceneXPlugin,AutoGPTTwitter"
        NEWSAPI_API_KEY=""
        
        # Pythong setup - based on https://github.com/mclare/Auto-GPT/blob/master/Dockerfile
        PIP_NO_CACHE_DIR="yes"
        PYTHONUNBUFFERED=1
        PYTHONDONTWRITEBYTECODE=1
        
        # Setup for Weaviate in Nomad
        MEMORY_BACKEND = "weaviate"
        HOST_IP = "${attr.unique.network.ip-address}"
        WEAVIATE_HOST = "${attr.unique.network.ip-address}" #Diplicate, but needed for Weaviate and Python to communicate, and HOST_IP is handy for other things
        WEAVIATE_PORT = 9090
        WEAVIATE_PROTOCOL = "http"

        WEAVIATE_EMBEDDED_PATH="/common/autogpt/weaviate" # this is optional and indicates where the data should be persisted when running an embedded instance
        USE_WEAVIATE_EMBEDDED="False" # set to True to run Embedded Weaviate
        MEMORY_INDEX="Autogpt" # name of the index to create for the application

        USE_WEB_BROWSER="chrome" # set to firefox or chrome to open a web browser to the application

        # Setup for Gotty
        GOTTY_VERSION="v1.0.1" # version of gotty to use
      }

      resources {
        cpu    = 2048
        memory = 850
      }

    }

    task "weaviate" {
      driver = "docker"

      config {
        image  = "semitechnologies/weaviate"
        ports  = ["weaviate"]
        volumes  = ["/media/cluster/common/autogpt/weaviate/data/:/data/"] #Nomad client must have docker.volumes.enabled = true https://developer.hashicorp.com/nomad/docs/drivers/docker#client-requirements
      }

    env { 
        QUERY_DEFAULTS_LIMIT = 25
        AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED = "true"
        PERSISTENCE_DATA_PATH = "./data'"
        DEFAULT_VECTORIZER_MODULE = "none"
        CLUSTER_HOSTNAME = "node1"

        HOST_IP = "${attr.unique.network.ip-address}"
      }

      resources {
        cpu    = 100
        memory = 128
      }
      
    }
  }
}
