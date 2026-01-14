FROM jenkins/jenkins:lts

USER root

# התקנת Docker CLI בתוך הקונטיינר
RUN apt-get update && \
    apt-get install -y docker.io curl && \
    rm -rf /var/lib/apt/lists/*

# חזרה למשתמש Jenkins
USER jenkins
