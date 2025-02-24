
####   2nd code #######################
#!/bin/bash

NEXUS_URL="https://3.7.107.149:8081"
REPO_NAME="docker-registry"
NEXUS_USER="admin"
NEXUS_PASS="kEYJUsaY4Z4s08oF"
NUM_IMAGES_TO_KEEP=10

# Authenticate to Nexus
TOKEN=$(curl -s -X POST -H "Content-Type: application/json" -d '{"username":"'${NEXUS_USER}'","password":"'${NEXUS_PASS}'"}' ${NEXUS_URL}/service/rest/v1/security/session | jq -r '.access_token')
AUTH_HEADER="Authorization: Bearer ${TOKEN}"

# Get a list of all images in the repository
IMAGE_LIST=$(curl -s -H "${AUTH_HEADER}" ${NEXUS_URL}/repository/${REPO_NAME}/images | jq -r '.items[].digest' | sort -r)

# Get the number of images to remove
NUM_IMAGES_TO_REMOVE=$(echo "${IMAGE_LIST}" | wc -l | tr -d ' ')

if [ ${NUM_IMAGES_TO_REMOVE} -gt ${NUM_IMAGES_TO_KEEP} ]; then
  # Remove all but the latest 10 images
  IMAGES_TO_REMOVE=$(echo "${IMAGE_LIST}" | tail -n +$((${NUM_IMAGES_TO_KEEP}+1)))
  for image in ${IMAGES_TO_REMOVE}; do
    curl -s -X DELETE -H "${AUTH_HEADER}" ${NEXUS_URL}/repository/${REPO_NAME}/docker/${image}
    echo "Removed image ${image}"
  done
else
  echo "No images to remove"
fi


  ######3rd code ###########################
pipeline {
  agent any
  
  stages {
    stage('Find and Purge Old Images') {
      steps {
        sh '''
          # Variables
          NEXUS_BASE_URL="http://3.7.107.149:8081/repository/docker-registry/
          #NEXUS_BASE_URL="https://<your-nexus-url>/repository/<your-repo>"
          NEXUS_USER="admin"
          NEXUS_PASSWORD="kEYJUsaY4Z4s08oF"
          REPO_PATH="repository/docker-registry"
          IMAGE_TYPE="docker-registry" # Example: docker

          # Calculate timestamp for 30 days ago
          TIME=$(date +%s)
          TIME=$((TIME - 2592000)) # 2592000 seconds = 30 days

          # Find images older than 30 days
          curl -s -u "${NEXUS_USER}:${NEXUS_PASSWORD}" "${NEXUS_BASE_URL}/${REPO_PATH}/${IMAGE_TYPE}/v2/_catalog" \
            | jq -r '.repositories[]' \
            | while read REPO; do
              curl -s -u "${NEXUS_USER}:${NEXUS_PASSWORD}" "${NEXUS_BASE_URL}/${REPO_PATH}/${IMAGE_TYPE}/v2/${REPO}/tags/list" \
                | jq -r ".tags[] | select(.[0:10] | tonumber < ${TIME})" \
                | while read TAG; do
                  echo "Deleting ${NEXUS_BASE_URL}/${REPO_PATH}/${IMAGE_TYPE}/v2/${REPO}:${TAG}"
                  curl -X DELETE -u "${NEXUS_USER}:${NEXUS_PASSWORD}" "${NEXUS_BASE_URL}/${REPO_PATH}/${IMAGE_TYPE}/v2/${REPO}/manifests/${TAG}"
                done
            done
        '''
      }
    }
  }
}



##############4th code#################################

#!/bin/bash

# Variables
NEXUS_BASE_URL="https://<your-nexus-url>/repository/<your-repo>"
NEXUS_USER="<your-nexus-username>"
NEXUS_PASSWORD="<your-nexus-password>"
REPO_PATH="<your-repo-path>"
IMAGE_TYPE="<your-image-type>" # Example: docker

# Calculate timestamp for 30 days ago
TIME=$(date +%s)
TIME=$((TIME - 2592000)) # 2592000 seconds = 30 days

# Find images older than 30 days
curl -s -u "${NEXUS_USER}:${NEXUS_PASSWORD}" "${NEXUS_BASE_URL}/${REPO_PATH}/${IMAGE_TYPE}/v2/_catalog" \
  | jq -r '.repositories[]' \
  | while read REPO; do
    curl -s -u "${NEXUS_USER}:${NEXUS_PASSWORD}" "${NEXUS_BASE_URL}/${REPO_PATH}/${IMAGE_TYPE}/v2/${REPO}/tags/list" \
      | jq -r ".tags[] | select(.[0:10] | tonumber < ${TIME})" \
      | while read TAG; do
        echo "Deleting ${NEXUS_BASE_URL}/${REPO_PATH}/${IMAGE_TYPE}/v2/${REPO}:${TAG}"
        curl -X DELETE -u "${NEXUS_USER}:${NEXUS_PASSWORD}" "${NEXUS_BASE_URL}/${REPO_PATH}/${IMAGE_TYPE}/v2/${REPO}/manifests/${TAG}"
      done
  done


#######5th code ################################

pipeline {
  agent any
  
  stages {
    stage('Find and Purge Old Images') {
     steps {
        sh '''
          # Variables
          NEXUS_BASE_URL="http://3.7.107.149:8081/repository/docker-registry/"
          NEXUS_USER="admin"
          NEXUS_PASSWORD="kEYJUsaY4Z4s08oF"
          REPO_PATH="repository/docker-registry"
          IMAGE_TYPE="docker" # Example: docker
          REPO="balance-calculator-service"
          TAG="0.0.1-4"
          KEEP_COUNT=5

          # Calculate timestamp for 30 days ago
          TIME=$(date +%s)
          TIME=$((TIME - 2592000)) # 2592000 seconds = 30 days

          # Find images older than 30 days
          OLDER_IMAGES=($(curl -s -u "${NEXUS_USER}:${NEXUS_PASSWORD}" "${NEXUS_BASE_URL}/${REPO_PATH}/${IMAGE_TYPE}/v2/_catalog" \
            | jq -r '.repositories[]' \
            | while read REPO; do
              curl -s -u "${NEXUS_USER}:${NEXUS_PASSWORD}" "${NEXUS_BASE_URL}/${REPO_PATH}/${IMAGE_TYPE}/v2/${REPO}/tags/list" \
                | jq -r ".tags[] | select(.[0:10] | tonumber < ${TIME})" \
                | while read TAG; do
                  echo "${NEXUS_BASE_URL}/${REPO_PATH}/${IMAGE_TYPE}/v2/${REPO}:${TAG}"
                done
            done))

          if [ ${#OLDER_IMAGES[@]} -eq 0 ]; then
            echo "No images older than 30 days found. Keeping last ${KEEP_COUNT} images."
            KEEP_IMAGES=($(curl -s -u "${NEXUS_USER}:${NEXUS_PASSWORD}" "${NEXUS_BASE_URL}/${REPO_PATH}/${IMAGE_TYPE}/v2/_catalog" \
              | jq -r '.repositories[]' \
              | while read REPO; do
                curl -s -u "${NEXUS_USER}:${NEXUS_PASSWORD}" "${NEXUS_BASE_URL}/${REPO_PATH}/${IMAGE_TYPE}/v2/${REPO}/tags/list" \
                  | jq -r '.tags[]' \
                  | tail -n ${KEEP_COUNT} \
                  | while read TAG; do
                    echo "${NEXUS_BASE_URL}/${REPO_PATH}/${IMAGE_TYPE}/v2/${REPO}:${TAG}"
                  done
              done))
            IMAGES_TO_DELETE=($(comm -23 <(printf '%s\n' "${ALL_IMAGES[@]}" | sort) <(printf '%s\n' "${KEEP_IMAGES[@]}" | sort)))
          else
            IMAGES_TO_DELETE=${OLDER_IMAGES[@]}
          fi

          # Delete images
          for IMAGE in "${IMAGES_TO_DELETE[@]}"; do
            echo "Deleting ${IMAGE}"
            curl -X DELETE -u "${NEXUS_USER}:${NEXUS_PASSWORD}" "${IMAGE}"
          done
        '''
      }
    }
  }
}
