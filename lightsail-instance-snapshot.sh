#!/bin/bash

# Create and maintain Lightsail Instance snapshots using AWS CLI
# Author: Seff P
# Version: 20201210


shopt -s nocasematch

AWS_CLI="/usr/local/bin/aws"
RETENTION_DEFAULT=1
REGION=ap-south-1
PREFIX="snapof"

export AWS_PROFILE=ss-lightsail-backup
export AWS_DEFAULT_REGION=${REGION}
export AWS_DEFAULT_OUTPUT=json

echo "INFO: Starting LightSail Backup Task"
REGIONS=$(${AWS_CLI} lightsail get-regions | jq -r '.regions[] | .name')

for REGION in ${REGIONS}
	do
	echo "INFO: Finding instances on region ${REGION}"
	export AWS_DEFAULT_REGION=${REGION}
	INSTANCES=$(${AWS_CLI} lightsail get-instances | jq -r '.instances[] | .name')
	for INSTANCE in ${INSTANCES}
		do
		echo "INFO: Processing instance $INSTANCE"
		TAGS=$(${AWS_CLI} lightsail get-instance --instance-name ${INSTANCE} | jq -r .instance.tags[])
		BACKUP_ENABLED=$(echo "$TAGS" | jq -r 'select(.key=="backup.enable") | .value')
		if [[ "$BACKUP_ENABLED" == "true" ]]
			then
			echo "INFO: Backup is enabled for $INSTANCE, creating backup"
			SNAPSHOT="${PREFIX}-${INSTANCE}-$(date +%Y%m%d_%H%M)"
			${AWS_CLI} lightsail create-instance-snapshot --instance-snapshot-name $SNAPSHOT --instance-name $INSTANCE --output text
			let SNAPSHOTS_CREATED=$SNAPSHOTS_CREATED+1
			BACKUP_RETENTION=$(echo "$TAGS" | jq -r 'select(.key=="backup.retention") | .value')
			if [[ "$BACKUP_RETENTION" =~ ^[0-9]+$ ]]
				then
				echo "INFO: Backup retention count is $BACKUP_RETENTION"
			else
				echo "DEBUG: Backup retention invalid. Tag value backup.retention=$BACKUP_RETENTION"
				echo "WARNING: Fall back to default retention $RETENTION_DEFAULT"
				BACKUP_RETENTION=${RETENTION_DEFAULT}
			fi
			SNAPSHOTS=$(${AWS_CLI} lightsail get-instance-snapshots| jq -r '.instanceSnapshots[] | .name' | grep "${PREFIX}-${INSTANCE}" | sort -r)
			SNAPSHOTS_COUNT=$(echo "$SNAPSHOTS" | grep -c .)
			if [[ $SNAPSHOTS_COUNT -gt $BACKUP_RETENTION ]]	
				then
				for SNAPSHOT in $(echo "${SNAPSHOTS}" | tail -n +$((${BACKUP_RETENTION}+1)))
					do
					echo "INFO: Deleting snapshot ${SNAPSHOT}"
					${AWS_CLI} lightsail delete-instance-snapshot --instance-snapshot-name ${SNAPSHOT} --output text
					let SNAPSHOTS_DELETED=$SNAPSHOTS_DELETED+1
				done
			else
				echo "INFO: Snapshot count $SNAPSHOTS_COUNT is not crossed retention count $BACKUP_RETENTION"
			fi
		else
			echo "WARNING: Backup is not enabled for $INSTANCE. Tag value backup.enable=$BACKUP_ENABLED"
		fi
		echo
	done
done

echo "INFO: Snapshots created: $SNAPSHOTS_CREATED"
echo "INFO: Snapshots deleted: $SNAPSHOTS_DELETED"
echo "INFO: LightSail Backup Task completed"
