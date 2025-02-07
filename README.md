# Automation Process

## 1. Setting Up AWS and GitHub Actions
1. Create an **AWS EC2 Key Pair** and add the **private key** to the GitHub Action environment.
2. Add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to the GitHub Action environment.
3. Push changes to the **prod** branch and merge them into the **main** branch to trigger the automation.
4. The GitHub Action workflow (`main.yml`) is executed.

## 2. GitHub Action Workflow Overview
The workflow consists of **three jobs**:

### **A. Infrastructure Setup**
This job provisions the infrastructure and sets up dependencies on an Ubuntu job runner:
1. Install Python.
2. Install AWS CLI and `boto3`.
3. Configure AWS credentials.
4. Run Terraform:
   - Execute a script to check for an existing IAM user with permissions to push images to AWS ECR. If found, it deletes it.
   - Validate existing resources (gateway, subnets, VPC, and EC2 role) and import them into Terraform if they exist.
5. Run `terraform apply` to create a new IAM user with AWS ECR push permissions.
6. Output the **new IAM user’s Access Key and Secret Key** for the next job.

### **B. Docker Build and Push**
This job builds and pushes Docker images from an EC2 instance to AWS ECR:
1. Configure AWS credentials with the **new IAM user** created in the previous job.
2. Authenticate the EC2 instance with AWS ECR.
3. Build Docker images using `Dockerfile_myapp` and `Dockerfile_mydb` from the GitHub repository.
4. Push the built images to AWS ECR.

### **C. Deploy Application to EC2 with Ansible**
This job deploys the application using Ansible:
1. Install Python, `pip`, `boto3`, and `botocore`.
2. Install Ansible.
3. Configure AWS credentials in the GitHub Action job runner.
4. Execute Ansible with the inventory file (`aws_ec2.yml`) and playbook (`deploy.yml`):
   - Dynamically update the EC2 instance IP address.
   - Authenticate and log in to the EC2 instance.
   - Execute the `deploy.yml` Ansible playbook:
     1. Install and restart Docker.
     2. Install Docker Compose.
     3. Copy the Docker Compose file from the GitHub repository to the EC2 instance.
     4. Adjust Docker permissions: `sudo usermod -aG docker $USER`.
     5. Authenticate with AWS ECR.
     6. Run Docker Compose to pull and start the application.

## 3. Deployment Result
- Three applications are deployed, each connecting to a **database container** with a **persistent volume** in AWS ECR.
- All four containers are within the **same network**, allowing communication between them.
- Applications are accessible on **ports 8081, 8082, and 8083** inside the EC2 instance.

## 4. Application Screenshots
Include the following images:
- **App 1:** `![App 1](images/APP1.PNG)`
- **App 2:** `![App 2](images/APP2.PNG)`
- **App 3:** `![App 3](images/APP3.PNG)`
- **Ping Test:** `![Ping Test](images/Ping.PNG)`


# Manual Installation Process
# Install the required MySQL package
```
sudo apt-get update -y
sudo apt-get install mysql-client -y
```

# Running application locally
```
pip3 install -r requirements.txt
python3 app.py
```

# Building and running 2 tier web application locally
### Building mysql docker image 
```
docker build -t my_db -f Dockerfile_mysql . 
```

### Building application docker image 
```
docker build -t my_app -f Dockerfile . 
```

### Running mysql
```
docker run -d -e MYSQL_ROOT_PASSWORD=pw  my_db
```


### Get the IP of the database and export it as DBHOST variable
```
docker inspect <container_id>
```


### Example when running DB runs as a docker container and app is running locally
```
export DBHOST=127.0.0.1
export DBPORT=3307
```
### Example when running DB runs as a docker container and app is running locally
```
export DBHOST=172.17.0.2
export DBPORT=3306
```
```
export DBUSER=root
export DATABASE=employees
export DBPWD=pw
export APP_COLOR=blue
```
### Run the application, make sure it is visible in the browser
```
docker run -p 8080:8080 -e APP_COLOR=$APP_COLOR -e DBHOST=$DBHOST -e DBPORT=$DBPORT -e DBUSER=$DBUSER -e DBPWD=$DBPWD  my_app
```
