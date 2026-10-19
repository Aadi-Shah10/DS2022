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

**Where you work.** Each step says where to do it:

- **Learner Lab page**: the AWS Academy page in your browser with **Start Lab**, **End Lab** and **AWS Details**.
- **AWS Console**: the AWS web interface in your browser, opened from the green **AWS** icon on the Learner Lab page.
- **Terminal on your computer**: your Mac Terminal or WSL shell. The `aws` CLI, the Python scripts and `ssh` run here.
- **Shell on the instance**: the remote Linux shell you get after `ssh` connects. The prompt changes to `ubuntu@ip-...`. Type `exit` to return to the terminal on your computer.



## In-class exercises


| Part | Activity                                        | Time   |
| ---- | ----------------------------------------------- | ------ |
| 1    | Recap: S3 from Python (demo)                    | 15 min |
| --   | Lecture intro to EC2                            | 20 min |
| 2    | Launch an EC2 instance in the AWS Console + SSH | 15 min |
| 3    | Launch an EC2 instance from the CLI + clean up  | 20 min |




### Before you start

1. On the **Learner Lab page**, click **Start Lab** and wait for the green **AWS** icon. See [Start the AWS Academy Learner Lab (class/06-s3)](../06-s3/README.md#start-the-aws-academy-learner-lab).
2. On the **Learner Lab page**, click **AWS Details** (top right) → **AWS CLI** → **Show**. Copy the block into `~/.aws/credentials` on your computer (credentials change with every lab session).
  - **Quick tip:** In Cursor, open a chat window and enter this prompt: "open ~/.aws/credentials, create a new file if it doesn't exist". Paste your credentials. **Save the file!**
3. On the **Learner Lab page**, click **AWS Details** → **SSH key** → **Download PEM**. Your browser downloads `labsuser.pem`, the private key of the `vockey` key pair that already exists in your lab account. Next, move it into `~/.ssh` on your computer and make it read-only for you.

Open a **terminal on your computer**. Then,
   **Mac:**

   **WSL:** the browser saves the file in your Windows `Downloads` folder, which WSL sees under `/mnt/c/Users/<windows-user>/`. Replace `<windows-user>` with your Windows user name:

   The key must live inside WSL (`~/.ssh`): `chmod` has no effect on files under `/mnt/c`, and `ssh` refuses keys that other users can read.

### 1. Recap: S3 from Python (15 minutes)

In the **terminal on your computer**, run three scripts from **[class/06-s3](../06-s3/)** inside the `.venv` you created last session:

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

```

### 2. S3 in the AWS Console (5 min)

1. On the **Learner Lab page**, click the green **AWS** icon to open the **AWS Console**.
2. In the **AWS Console**, search for **S3** in the top search bar and open it.
3. Find `practice-<your user name>` in the list of **General purpose buckets**. This is the bucket the script just created.
4. Open the bucket and check the tabs **Objects**, **Properties** (region, creation date) and **Permissions** (**Block public access** is on).
5. Optional: In the **AWS Console**, **Upload** a small file. Then list it from the **terminal on your computer**:
  ```bash
   aws s3 ls s3://practice-$USER/
  ```

---

### 2. Launch an EC2 instance in the AWS Console (15 min)

Steps 1–4 happen in the **AWS Console**. Make sure the region in the top right corner of the console is **N. Virginia (us-east-1)**, the same region as in `~/.aws/config` on your computer.

1. In the **AWS Console**, search for **EC2** and open it. Click **Launch instance**.
2. Fill in the form; leave everything else at its default:

  | Setting                       | Value                                                                      |
  | ----------------------------- | -------------------------------------------------------------------------- |
  | **Name**                      | `ec2-console`                                                              |
  | **Application and OS Images** | **Ubuntu**, *Ubuntu Server 26.04 LTS* (Free tier eligible)                 |
  | **Instance type**             | `t3.micro`                                                                 |
  | **Key pair (login)**          | `vockey`                                                                   |
  | **Network settings**          | **Create security group**, **Allow SSH traffic from** *Anywhere* (default) |
  | **Configure storage**         | 8 GiB gp3 (default)                                                        |
  | **File systems**              | None (default)                                                             |

3. Click **Launch instance**, then **View all instances**.
4. Wait until **Instance state** is *Running* and **Status check** shows *2/2 checks passed* (1-2 min). Check the box in front of the the instance name and look at the **Details** tab: **Instance ID**, **Public IPv4 address**, **AMI ID**, and under **Security** the security group `launch-wizard-1`.
5. In the **AWS Console**, copy the **Public IPv4 address** to your clipboard. In the **terminal on your computer**, connect to the instance (replace `<public-ip>` with that address):
  ```bash
   ssh -i ~/.ssh/labsuser.pem ubuntu@<public-ip>
  ```
   Type `yes` to trust the host key on first connect. Ubuntu AMIs use the user name `ubuntu` (Amazon Linux uses `ec2-user`). Once connected, the prompt changes to `ubuntu@ip-...`: you are now in the **shell on the instance**.
6. In the **shell on the instance**, run the following commands to explore your instance:
  ```bash
   hostname
   whoami
   nproc          # number of CPUs
   free -h        # memory
   df -h /        # disk
  ```
  Then log out, which returns you to the **terminal on your computer**:
  ```bash
   exit
  ```

If `ssh` reports `Permission denied (publickey)`, check the key path and run `chmod 400 ~/.ssh/labsuser.pem` in the **terminal on your computer**. Make sure to log in with username `ubuntu`. If it hangs, check in the **AWS Console** (EC2 → Instances → select the instance → **Security** tab) that the security group allows inbound SSH (port 22).

Leave the instance running; part 3 reuses its AMI and security group.

### 3. Launch an EC2 instance from the CLI (20 min)

Run all commands in this part in the **terminal on your computer**, except where a step says **shell on the instance**. The `aws` CLI on your computer has your lab credentials; the instance does not. Use one terminal window for the whole part: the shell variables `$IID` and `$IP` exist only in the terminal where you set them.

`aws ec2 run-instances` takes the same choices you made in the console form, as options:

- **AMI:** `ami-0b6d9d3d33ba97d99` is *Ubuntu Server 26.04 LTS* in us-east-1, the same image the console used in part 2. To confirm, in the **AWS Console** select `ec2-console` and compare its **AMI ID** on the **Details** tab.
- **Security group:** `launch-wizard-1` is the security group the console created in part 2. If you created more than one, check the name under the instance's **Security** tab in the **AWS Console**.

**Launch the instance**

```bash
IID=$(aws ec2 run-instances \
  --image-id ami-0b6d9d3d33ba97d99 \
  --instance-type t3.micro \
  --key-name vockey \
  --security-groups launch-wizard-1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ec2-cli}]' \
  --query 'Instances[0].InstanceId' --output text)
echo $IID
```

`--query` picks fields out of the JSON response (try the command without `--query` and `--output text` to see the full response).

> **Optional:** [launch-ec2-cli.sh](launch-ec2-cli.sh) does the same launch without hard-coding the AMI and security group IDs: it reads both from the running `ec2-console` instance, launches `ec2-cli`, waits for it and prints the `ssh` command. Run it in the **terminal on your computer** with `bash launch-ec2-cli.sh`.


| Option                 | Console field                     |
| ---------------------- | --------------------------------- |
| `--image-id`           | Application and OS Images (AMI)   |
| `--instance-type`      | Instance type                     |
| `--key-name`           | Key pair (login)                  |
| `--security-groups`    | Network settings → security group |
| `--tag-specifications` | Name                              |


Without `--subnet-id`, AWS picks a subnet in the default VPC, which is how the console launched `ec2-console` as well.

**Wait for it and connect**

```bash
aws ec2 wait instance-running --instance-ids $IID
IP=$(aws ec2 describe-instances --instance-ids $IID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo $IP
ssh -i ~/.ssh/labsuser.pem ubuntu@$IP
```

`wait instance-running` returns once the instance is running, but SSH may refuse connections for another 30 seconds while it boots. Retry if needed. In the **shell on the instance**, run `hostname`, then `exit` to return to the **terminal on your computer**.

In the **AWS Console**, refresh **EC2 → Instances**: `ec2-console` and `ec2-cli` are listed side by side.

Back in the **terminal on your computer**, list all your instances in a table:

```bash
aws ec2 describe-instances \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,InstanceId,State.Name,PublicIpAddress]' \
  --output table
```

**Clean up**

In the **terminal on your computer**, terminate both instances. Terminating is permanent: the instance and its disk are deleted.

Copy the instance ID of `ec2-console` (starts with `i-`) from the table above and replace `<ec2-console-id>` with it. `$IID` still holds the ID of `ec2-cli`.

```bash
aws ec2 terminate-instances --instance-ids $IID <ec2-console-id>
```

Wait a minute, then run the `describe-instances` table command again: both instances show `shutting-down`, then `terminated`, and disappear from the list after about an hour. The **AWS Console** shows the same states under **EC2 → Instances** after a refresh.

> When the Learner Lab session ends, running instances are **stopped**, not terminated, and start again with your next **Start Lab**. Stopped and running instances use up your lab budget, so terminate instances you no longer need.

## Resources

- [Launch an EC2 instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/LaunchingAndUsingInstances.html)
- [Amazon EC2 instance types](https://aws.amazon.com/ec2/instance-types)
- [AWS CLI reference:](https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html) `ec2 run-instances`
- [Filter AWS CLI output with](https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-filter.html) `--query`
- [Amazon EC2 security groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)
- [Instance lifecycle (stop, start, terminate)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-lifecycle.html)

## Troubleshooting

**Status check does not show 2/2 checks passed (AWS Console).** Newer instance types such as `t3.micro` run three checks and show *3/3 checks passed*. *Initializing* means the checks are still running; click the refresh button. If the **Status check** column is missing, turn it on under the gear icon (Preferences) above the instance list.

**`ExpiredToken` or `InvalidClientTokenId` (terminal on your computer).** Your lab credentials changed. On the **Learner Lab page**, copy the new block from **AWS Details** → **AWS CLI** → **Show** into `~/.aws/credentials` on your computer.

**`Unable to locate credentials` (shell on the instance).** You ran an `aws` command on the instance. Type `exit` and run it in the **terminal on your computer**.

**`ssh`: `Permission denied (publickey)` (terminal on your computer).** Check the key path, run `chmod 400 ~/.ssh/labsuser.pem`, and log in as `ubuntu`.

**`ssh`: `UNPROTECTED PRIVATE KEY FILE` (terminal on your computer).** The key is readable by other users. Run `chmod 400 ~/.ssh/labsuser.pem`. On WSL, the key must be in `~/.ssh`, not under `/mnt/c`.

**`ssh` hangs or times out.** In the **AWS Console** (EC2 → Instances → select the instance → **Security** tab), check that the security group allows inbound SSH (port 22). Also check that you use the instance's current **Public IPv4 address** (it changes when the instance is stopped and started).

**`ssh`: `Connection refused` right after launch.** The instance is still booting. Wait 30 seconds and retry from the **terminal on your computer**.

**`run-instances`: `InvalidGroup.NotFound` (terminal on your computer).** Your security group has a different name. In the **AWS Console**, select `ec2-console` and check the name on the **Security** tab (e.g. `launch-wizard-2`), then use that name with `--security-groups`.

**`echo $IID` or `echo $IP` prints nothing.** You opened a new terminal window or tab, so the shell variables are gone. Run the commands that set them again in the same terminal.

**`01-make-bucket.py`: `BucketAlreadyExists`.** Another AWS account owns `practice-$USER`. Bucket names are global; use `practice-$USER-1` instead.

