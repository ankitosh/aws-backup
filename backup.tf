####################################################
# Author :  Ankit Upadhyay
# Replace Ankit with your Company Name.
####################### Variables ##################

##### KMS KEY #####

data "aws_kms_key" "key" {
  key_id = "alias/abcd"
}

#### AWS BACKUP ROLE ################

resource "aws_iam_role" "backup_role" {
  name               = "ANKIT-BACKUP-ROLE"  
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:AssumeRole"],
      "Effect": "allow",
      "Principal": {
        "Service": ["backup.amazonaws.com"]
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "example" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = "${aws_iam_role.backup_role.name}"
}



#### Backup Vault #############

resource "aws_backup_vault" "Ankit_backup_vault" {
  name                  = "Ankit-daily-backup-vault"
  kms_key_arn           = "${data.aws_kms_key.key.arn}"
 /* 
 # UnComment to use tags.
  tags                            = {
    Name               = "${var.Region}-${var.env}-BK-${var.service}"
    Environment        = "${var.Environment}"
    Owner              = "${var.Owner}"
    CostCenter         = "${var.CostCenter}"
    Description        = "${var.Environment} Backup Vault"
}
*/
}

####  Backup Plan ####

resource "aws_backup_plan" "Ankit_backup_plan" {
  name               = "Ankit-DAILY-BACKUP-PLAN"

  rule {
    rule_name           = "Ankit-daily-backup-plan"
    target_vault_name   = "${aws_backup_vault.Ankit_backup_vault.name}"
    schedule            = "cron(0 0-4 * * ? *)" # Change as per Schedule.
    start_window        = 60
    lifecycle {
        cold_storage_after  = 15
        delete_after        = 180
        }
      
  }
}

########### Backup Selection ########################

resource "aws_backup_selection" "backup_selection" {
  iam_role_arn = "${aws_iam_role.backup_role.arn}"
  name         = "Daily_Backup_Selection"
  plan_id      = "${aws_backup_plan.Ankit_backup_plan.id}"

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "BACKUP"
    value = "YES"
  }
}