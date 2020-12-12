# lightsail-instance-snapshot
Create and retain LightSail Instance snapshot based on tags using AWS CLI

# Enabling Automatic Snapshots
We can manage the backups using TAG - KEY pairs created for each Instances.

| KEY              | VALUE | TYPE    | DEFAULT | NOTES                                                                                                                                      |
|------------------|-------|---------|---------|--------------------------------------------------------------------------------------------------------------------------------------------|
| backup.enable    |  true | Boolean |   NULL  | Case-insensitive. Any value other than true will disable automatic backups. If disabled, existing backups won't be removed automatically. |
| backup.retention | [0-9] |  Digit  |    1    |                Maximum number of backups retained which begins with ${PREFIX}. The value 0  will remove all backups.                |

# Tweaks

The path to the AWS CLI can be set using `AWS_CLI="/usr/local/bin/aws"`

The AWS Credentials Profile is defined using `AWS_PROFILE=lightsail-backup`

The snapshot name created by the script can be tweaked using
```
PREFIX="snapshot"
SNAPSHOT="${PREFIX}-${INSTANCE}-$(date +%Y%m%d_%H%M)"
```
When the retention is not specified as the TAG-KEY, the default value of 1 will be used. This value can be tweaked using the variable `RETENTION_DEFAULT=1`
The script only removes snapshots which name begins with `${PREFIX}` variable

# IAM Policy
The IAM user should have the following permissions for the LightSail service:

 - GetInstanceSnapshot
 - GetInstanceSnapshots
 - GetInstances
 - GetRegions
 - DeleteInstanceSnapshot
