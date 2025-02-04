import boto3
import os
from botocore.exceptions import ClientError

# Initialize AWS EC2 client
ec2_client = boto3.client('ec2', region_name='us-east-1')  # Replace with your desired region

key_pair_name = 'ec2_key'  # Name of the key pair

# Function to check if the key pair exists
def check_key_pair_exists(key_pair_name):
    try:
        # List key pairs and check if the desired key pair exists
        response = ec2_client.describe_key_pairs(KeyNames=[key_pair_name])
        if 'KeyPairs' in response and len(response['KeyPairs']) > 0:
            return True  # The key pair exists
        return False  # The key pair does not exist
    except ClientError as e:
        if 'InvalidKeyPair.NotFound' in str(e):
            return False  # The key pair does not exist
        else:
            raise

# Check if the key pair exists
if check_key_pair_exists(key_pair_name):
    print(f"Key pair '{key_pair_name}' already exists.")
else:
    # Create a new EC2 Key Pair
    response = ec2_client.create_key_pair(KeyName=key_pair_name)

    # Extract the private key
    private_key = response['KeyMaterial']

    # Expand the tilde to the full home directory path
    file_path = os.path.expanduser(f"~/.ssh/{key_pair_name}.pem")           # pwd: /home/behzad_ubuntu

    # Create the .ssh directory if it doesn't exist
    os.makedirs(os.path.dirname(file_path), exist_ok=True)

    # Save the private key to a .pem file
    with open(file_path, "w") as private_key_file:
        private_key_file.write(private_key)

    print(f"Key pair '{key_pair_name}' created and saved as '{key_pair_name}.pem'")
