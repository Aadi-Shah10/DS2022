# AWS EC2 Compute

> [!CAUTION]
> **Do NOT click Reset in the AWS Academy Learner Lab unless your instructor tells you to.**
> Reset permanently deletes everything in your lab account (S3 buckets, EC2 instances, Lambda functions, ...) and cannot be undone. To pause, click **End Lab**: your resources stay and are back with the next **Start Lab**.

This session introduces **Amazon EC2**, virtual machines you rent by the hour. Building on [S3](../06-s3/README.md), you will:

- recap the `boto3` S3 scripts and see the same buckets in the AWS Console
- launch an EC2 instance in the AWS Console and connect to it with SSH
- launch a second instance from the command line with `aws ec2 run-instances`
- terminate both instances

> All exercises use the **AWS Academy Learner Lab** and the AWS CLI / `boto3` setup from [S3](../06-s3/README.md).


## In-class exercises

| Part | Activity                                        | Time   |
| ---- | ----------------------------------------------- | ------ |
| 1    | Recap: S3 from Python (demo)                    | 15 min |
| --     | Lecture intro to EC2                            | 20 min |
| 2    | Launch an EC2 instance in the AWS Console + SSH | 15 min |
| 3    | Launch an EC2 instance from the CLI + clean up  | 20 min |


### Before you start

1. Start the Learner Lab (**Start Lab**, wait for the green **AWS** icon). See [Start the AWS Academy Learner Lab](../06-s3/README.md#start-the-aws-academy-learner-lab).
2. **AWS Details** → **AWS CLI** → **Show**: copy the block into `~/.aws/credentials` (credentials change with every lab session).
   - **Quick tip:** In Cursor, open a chat window and enter this prompt: "open ~/.aws/credentials, create a new file if it doesn't exist"
3. **AWS Details** → **SSH key** → **Download PEM**. This downloads `labsuser.pem`, the private key of the `vockey` key pair that already exists in your lab account. Move it into `~/.ssh` and make it read-only for you.

   **Mac:**

   ```bash
   mkdir -p ~/.ssh
   mv ~/Downloads/labsuser.pem ~/.ssh/
   chmod 400 ~/.ssh/labsuser.pem
   ```

   **WSL:** the browser saves the file in your Windows `Downloads` folder, which WSL sees under `/mnt/c/Users/<windows-user>/`. Replace `<windows-user>` with your Windows user name:

   ```bash
   mkdir -p ~/.ssh
   mv /mnt/c/Users/<windows-user>/Downloads/labsuser.pem ~/.ssh/
   chmod 400 ~/.ssh/labsuser.pem
   ```

   The key must live inside WSL (`~/.ssh`): `chmod` has no effect on files under `/mnt/c`, and `ssh` refuses keys that other users can read.


### 1. Recap: S3 from Python (15 minutes)

Run three scripts from **[class/06-s3](../06-s3/)** inside the `.venv` you created last session:

```bash
cd <path_to_your_cloned_fork_of_DS2022_repo>/class/06-s3
uv venv && uv pip install boto3
```

```bash
uv run python 00-check-aws-credentials.py   # same as: aws sts get-caller-identity
```

```bash
uv run python 01-make-bucket.py             # creates practice-$USER (error if it exists already)
```bash

The scripts and the `aws` CLI make the same API calls with the same credentials. The AWS Console is a third way to make those calls, with a browser.


### 2. S3 in the AWS Console (5 min)

1. In the Learner Lab, click the **AWS** icon to open the AWS Console.
2. Search for **S3** in the top search bar and open it.
3. Find `practice-<your user name>` in the list of **General purpose buckets**. This is the bucket the script just created.
4. Open the bucket and check the tabs **Objects**, **Properties** (region, creation date) and **Permissions** (**Block public access** is on).
5. Optional: **Upload** a small file, then list it from the terminal:

   ```bash
   aws s3 ls s3://practice-$USER/
   ```
---

### 2. Launch an EC2 instance in the AWS Console (15 min)

Make sure the region in the top right corner is **N. Virginia (us-east-1)**, the same region as in `~/.aws/config`.

1. Search for **EC2** and open it. Click **Launch instance**.
2. Fill in the form; leave everything else at its default:

   | Setting                       | Value                                                                    |
   | ----------------------------- | ------------------------------------------------------------------------ |
   | **Name**                      | `ec2-console`                                                            |
   | **Application and OS Images** | **Ubuntu**, *Ubuntu Server 24.04 LTS* (Free tier eligible)               |
   | **Instance type**             | `t3.micro`                                                               |
   | **Key pair (login)**          | `vockey`                                                                 |
   | **Network settings**          | **Create security group**, **Allow SSH traffic from** *Anywhere*         |
   | **Configure storage**         | 8 GiB gp3 (default)                                                      |

3. Click **Launch instance**, then **View all instances**.
4. Wait until **Instance state** is *Running* and **Status check** shows *2/2 checks passed* (1-2 min). Select the instance and look at the **Details** tab: **Instance ID**, **Public IPv4 address**, **AMI ID**, and under **Security** the security group `launch-wizard-1`.
5. Connect from your terminal (use the public IPv4 address of your instance):

   ```bash
   ssh -i ~/.ssh/labsuser.pem ubuntu@<public-ip>
   ```

   Type `yes` to trust the host key on first connect. Ubuntu AMIs use the user name `ubuntu` (Amazon Linux uses `ec2-user`).

6. Look around on the instance, then log out:

   ```bash
   hostname
   whoami
   nproc          # number of CPUs
   free -h        # memory
   df -h /        # disk
   exit
   ```

If `ssh` reports `Permission denied (publickey)`, check the key path, `chmod 400` on the key, and the user name `ubuntu`. If it hangs, check that the security group allows inbound SSH (port 22).

Leave the instance running; part 4 reuses its AMI and security group.


### 3. Launch an EC2 instance from the CLI (20 min)

`aws ec2 run-instances` takes the same choices you made in the console form, as options. Instead of looking up each ID in the console, read the AMI ID and security group ID from the instance you just launched:

```bash
AMI=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ec2-console" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].ImageId' --output text)
SG=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ec2-console" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)
echo $AMI $SG
```

`--query` picks fields out of the JSON response (try the command without `--query` and `--output text` to see the full response).

**Launch the instance**

```bash
IID=$(aws ec2 run-instances \
  --image-id $AMI \
  --instance-type t3.micro \
  --key-name vockey \
  --security-group-ids $SG \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ec2-cli}]' \
  --query 'Instances[0].InstanceId' --output text)
echo $IID
```

| Option                 | Console field                      |
| ---------------------- | ---------------------------------- |
| `--image-id`           | Application and OS Images (AMI)    |
| `--instance-type`      | Instance type                      |
| `--key-name`           | Key pair (login)                   |
| `--security-group-ids` | Network settings → security group  |
| `--tag-specifications` | Name                               |

Without `--subnet-id`, AWS picks a subnet in the default VPC, which is how the console launched `ec2-console` as well.

**Wait for it and connect**

```bash
aws ec2 wait instance-running --instance-ids $IID
IP=$(aws ec2 describe-instances --instance-ids $IID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo $IP
ssh -i ~/.ssh/labsuser.pem ubuntu@$IP
```

`wait instance-running` returns once the instance is running, but SSH may refuse connections for another 30 seconds while it boots. Retry if needed. Run `hostname` on the instance, then `exit`.

Switch to the console and refresh **Instances**: `ec2-console` and `ec2-cli` are listed side by side.

List all your instances in a table:

```bash
aws ec2 describe-instances \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,InstanceId,State.Name,PublicIpAddress]' \
  --output table
```

**Clean up**

Terminate both instances. Terminating is permanent: the instance and its disk are deleted.

```bash
CID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ec2-console" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' --output text)
aws ec2 terminate-instances --instance-ids $IID $CID
aws ec2 wait instance-terminated --instance-ids $IID $CID
```

Run the `describe-instances` table again: both instances show `terminated` and disappear from the list after about an hour.

> When the Learner Lab session ends, running instances are **stopped**, not terminated, and start again with your next **Start Lab**. Stopped and running instances use up your lab budget, so terminate instances you no longer need.


## Resources

- [Launch an EC2 instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/LaunchingAndUsingInstances.html)
- [Amazon EC2 instance types](https://aws.amazon.com/ec2/instance-types)
- [AWS CLI reference: `ec2 run-instances`](https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html)
- [Filter AWS CLI output with `--query`](https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-filter.html)
- [Amazon EC2 security groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)
- [Instance lifecycle (stop, start, terminate)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-lifecycle.html)
