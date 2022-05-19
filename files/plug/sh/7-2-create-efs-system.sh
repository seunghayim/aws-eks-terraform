#!/usr/bin/env sh

vpc_id=$(aws eks describe-cluster \
    --name multi05-eks-cluster-terraform \
    --query "cluster.resourcesVpcConfig.vpcId" \
    --output text)

cidr_range=$(aws ec2 describe-vpcs \
    --vpc-ids $vpc_id \
    --query "Vpcs[].CidrBlock" \
    --output text)

security_group_id=$(aws ec2 create-security-group \
    --group-name MyEfsSecurityGroup \
    --description "My EFS security group" \
    --vpc-id $vpc_id \
    --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $security_group_id \
    --protocol tcp \
    --port 2049 \
    --cidr $cidr_range

file_system_id=$(aws efs create-file-system \
    --region ap-southeast-2 \
    --performance-mode generalPurpose \
    --query 'FileSystemId' \
    --output text)

# 노드가 위치한 서브넷 추가 output 참조하여 변경
aws efs create-mount-target \
    --file-system-id $file_system_id \
    --subnet-id subnet-0582b1371228b58a2 \
    --security-groups $security_group_id

aws efs describe-file-systems --query "FileSystems[*].FileSystemId" --output text