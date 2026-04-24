#!/bin/bash

sg_id="sg-0edf74a4c129178e7"
ami_id="ami-0220d79f3f480ecf5"
zone_id="Z02669081FB4X7KDSL5OS"
domain_name="sainu.online"

for instance in $@
 do
    INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

     if [ $instance == "frontend" ]; then
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text
        )
        RECORD_NAME="$DOMAIN_NAME" # daws88s.online
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )
        RECORD_NAME="$instance.$DOMAIN_NAME" # mongodb.daws88s.online
    fi

    echo "IP Address: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating record",
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP'"
                }
                ]
            }
            }
        ]
    }
    '

    echo "record updated for $instance"

done

