<div align="center" padding=25px>
    <img src="images/confluent.png" width=50% height=50%>
</div>

# <div align="center">Data Migration from Apache Kafka to Confluent Cloud</div>
## <div align="center">Lab Guide</div>
<br>



## **Agenda**

1. [TBD](#step-1)
2. [TBD](#step-2)




## **Architecture**

<div align="center">
    <img src="images/architecture.png" width=75% height=75%>
</div>
<br>



## Prerequisites

Before you begin, ensure you have the following installed:

- **Confluent Cloud Account**
    - Sign-up for a Confluent Cloud account [here](https://www.confluent.io/confluent-cloud/tryfree/)
    - Once you have signed up and logged in, click on the menu icon at the upper right hand corner, click on "Billing & payment", then enter payment details under “Payment details & contacts”. A screenshot of the billing UI is included below.

    > **Note:** You will create resources during this workshop that will incur costs. When you sign up for a Confluent Cloud account, you will get free credits to use in Confluent Cloud. This will cover the cost of resources created during the workshop. More details on the specifics can be found [here](https://www.confluent.io/confluent-cloud/tryfree/).

- [Confluent CLI](https://docs.confluent.io/confluent-cli/current/install.html) - If on MAC run `brew install confluentinc/tap/cli`. 
- [Terraform](https://www.terraform.io/downloads.html) - v1.5.7 or later. 
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials.
- [Kafka CLI](https://kafka.apache.org/downloads) 

<details>
<summary>Installing prerequisites on MAC</summary>

Install the prerequisites by running:

```bash
brew install git terraform confluentinc/tap/cli awscli
```

</details>

<details>
<summary>Installing prerequisites on Windows</summary>

Install the prerequisites by running:

```powershell
winget install --id Git.Git -e
winget install --id Hashicorp.Terraform -e
winget install --id ConfluentInc.Confluent-CLI -e
winget install --id Amazon.AWSCLI -e
winget install --id Microsoft.OpenJDK.17 -e
```
</details> 



## Setup

1. Clone the repo onto your local development machine using `git clone https://github.com/confluentinc/XXXXXXXXXX.git`.
2. Change directory to demo repository and terraform directory.

   ```
   cd workshop-XXXXXXX-XXXXXXX/terraform
   ```
3. Configure AWS CLI

   If you already have the AWS CLI configured on your machine and pointing to the correct AWS account, you can skip this step.

   If you're using **AWS Workshop Studio**, click on **Get AWS CLI Credentials** to retrieve the necessary access key, secret key, and region. Then, run the following command to configure the CLI:
   <details>
   <summary>Click to expand for MAC</summary>

   ```bash
   export AWS_DEFAULT_REGION="<cloud_region>"
   export AWS_ACCESS_KEY_ID="<AWS_API_KEY>"
   export AWS_SECRET_ACCESS_KEY="<AWS_SECRET>"
   export AWS_SESSION_TOKEN="<AWS_SESSION_TOKEN>"
   ```

   </details>

   <details>
   <summary>Click to expand for Windows CMD</summary>

   ```bash
   set AWS_DEFAULT_REGION="<cloud_region>"
   set AWS_ACCESS_KEY_ID="<AWS_API_KEY>"
   set AWS_SECRET_ACCESS_KEY="<AWS_SECRET>"
   set AWS_SESSION_TOKEN="<AWS_SESSION_TOKEN>"
   ```


   </details>
4. Verify you are using the correct AWS account by running:

   ```
   aws sts get-caller-identity
   ```
   If you are using **AWS Workshop Studio**, you should have an output that looks like this:

   ```bash
   {
    "UserId": "AROA4AFJ7PWFSQYLGZ3YL:Participant",
    "Account": "xxxxxxxxxx",
    "Arn": "arn:aws:sts::xxxxxxxxxx:assumed-role/WSParticipantRole/Participant"
   }
   ```


## **Objective:**

**Acme.com**, a mid-sized e-commerce company runs a self-managed Open-Source Apache Kafka (OSK) cluster on-premises to handle real-time order events. As their customer base grows, maintaining uptime, scaling storage, and ensuring disaster recovery becomes increasingly challenging. To overcome these limitations and reduce operational overhead, they plan to migrate their data pipeline to Confluent Cloud.

This workshop simulates that scenario by:

- Setting up a local Kafka cluster to act as the on-prem system.
- Producing order events to simulate real-world workloads.
- Establishing a **Destination-Initiated Cluster Link** to pull topics and messages into Confluent Cloud.
- Validating successful data replication.
- Reconfiguring producers and consumers to point to Confluent Cloud, ensuring that consumers pick up from the latest offset post-migration.

By the end, participants will understand the complete migration process and key considerations for moving production workloads to the cloud.


## <a name="step-1"></a>**Step 1: Set up Open-Source Kafka (OSK)**

In this section, you will set up an OSK instance on AWS EC2 instance using a Terrform script. Execute the following steps to perform this task:

1. Open the repo directory in a new terminal window.
2. Change directory to `terraform` directory:
```
cd terraform
```
3. Initialize Terraform

   ```bash
   terraform init
   ```

6. Deploy OSK using Terrform

   ```bash
   terraform apply --auto-approve
   ```

Terraform will take around 10 mins to deploy and initialize OSK on AWS EC2 instance.

<br>

## <a name="step-2"></a>**Step 2: Set up Confluent Cloud and Create a Dedicated Cluster**

1. Log in to [Confluent Cloud](https://confluent.cloud) and enter your email and password.

<div align="center" padding=25px>
    <img src="images/login.png" width=50% height=50%>
</div>

2. If you are logging in for the first time, you will see a self-guided wizard that walks you through spinning up a cluster. Please minimize this as you will walk through those steps in this workshop. 


3. Click **+ Add Environment**. Specify an **Environment Name** and Click **Create**. 

    > ⚠️ **Note:** An environment contains clusters and its deployed components such as Connectors, ksqlDB, and Schema Registry. You have the ability to create different environments based on your company's requirements. Confluent has seen companies use environments to separate Development/Testing, Pre-Production, and Production clusters.
    
    >There is a *default* environment ready in your account upon account creation. You can use this *default* environment for the purpose of this workshop if you do not wish to create an additional environment.

<div align="center" padding=25px>
    <img src="images/environment.png" width=50% height=50%>
</div>

2. Now that you have an environment, click **Create Cluster**. 

    > ⚠️ **Note:** Confluent Cloud clusters are available in 3 types: Basic, Standard, and Dedicated. Basic is intended for development use cases so you will use that for the workshop. Basic clusters only support single zone availability. Standard and Dedicated clusters are intended for production use and support Multi-zone deployments. If you are interested in learning more about the different types of clusters and their associated features and limits, refer to this [documentation](https://docs.confluent.io/current/cloud/clusters/cluster-types.html).

3. Choose the **Dedicated** Cluster Type. 

<div align="center" padding=25px>
    <img src="images/cluster-type.png" width=50% height=50%>
</div>

4. Click **Begin Configuration**.
   
5. Choose your preferred Cloud Provider (AWS, GCP, or Azure), Region, and Availability Zone.

6. Make sure the **Internet** option is selected for Networking configuration.

7. Specify a **Cluster Name** - any name will work here. 

<div align="center" padding=25px>
    <img src="images/create-cluster.png" width=50% height=50%>
</div>

7. View the associated Configuration and Cost, Usage Limits, and Uptime SLA information before launching.

8. Click **Launch Cluster.** The dedicated cluster type takes around 20 - 30 minutes for provisioning.
   
<br>

## <a name="step-3"></a>**Step 3: Produce and Consume Data in OSK**

In this section, you will create a topic in OSK and populate it with sample data.

1. Open a new terminal and navigate to your Terraform directory and run:
   ```bash
   terraform output
   ```

   Look for the value of `kafka`. It should look like this:

   ```
   xxxxxxxxx-xxxxxxxx-xxxxxxx
   ```

2. Set this to the `OSK-BROKER` environment variable on your terminal:
    ```
    export OSK-BROKER=xxxxxxxxx-xxxxxxxx-xxxxxxx
    ```

3. Create a topic in OSK using the following command. You will use the `kafka-topics.sh` utility to create the topic:
    
    ```bash
    kafka-topics.sh --create --bootstrap-server OSK-BROKER:9092 --topic test-topic --partitions 1 --replication-factor 1
    ```

4. Produce some sample data using the `kafka-console-producer.sh` utility.

    ```bash
    kafka-console-producer.sh --bootstrap-server OSK-BROKER:9092 --topic test-topic
    ```

    Your terminal shows the prompt:

    ```
    >
    ```

    You type your first message and press Enter:

    ```
    > Hello Kafka
    ```

    The message "Hello Kafka" is now published to `test-topic`. The prompt appears again, ready for the next message:

    ```
    > This is a second message.
    ```

    The message "This is a second message." is published. You then press **Ctrl+C** to exit the producer.

<br>

## <a name="step-4"></a>**Step 4: Set up Cluster Linking**

To set up Cluster Linking in Confluent Cloud, follow these steps:

1. Log in to the Confluent Cloud Console and select **Cluster links** from the menu on the left.
2. Click **Create cluster link**.
3. In the Source Cluster configurations:

   	3.1. Select **Confluent Platform or Apache Kafka** as the Source Cluster.
   
   	3.2. Enter the source cluster Id (cluster id of your OSK).
   
   	3.3. Uncheck the **Source initiated connection** in the Security access section and provide the Bootstrap server URL of your OSK.
   
4. In the Destination Cluster configurations, select your environment and the dedicated cluster that you created previously.
5. In the Configuration page:

   5.1. Select **Enable for all existing and future source cluster topics** option in the Auto-create mirror topics section.

   5.2. Select **Sync all existing and future consumer groups** option in the Sync consumer offsets section.

6. Enter a Cluster link name, review your configurations, and click **Launch Cluster kink**.  

<br>

## <a name="step-5"></a>**Step 5: Verifying the Creation of the Mirror Topic in the Dedicated Cluster**

To verify creation of the mirror topics, execute the following steps:

1. To list all the mirror topics associated with the link, use the following command:

```bash
confluent kafka mirror list
```

2. To check the status and details of a specific mirror topic, execute the following command:

```bash
confluent kafka mirror describe <mirror-topic-name>
```
Look for the status to ensure it is in an active state and pulling records from the source.

3. You can also verify that data is being replicated properly by monitoring the lag and message count in the mirror topic using the following command:

```bash
confluent kafka topic describe <mirror-topic-name>
```
Check the estimated lag and ensure it reflects minimal delays, indicating that records are being pulled promptly from OSK.

<br>

## <a name="step-6"></a>**Step 6: Make the Mirror Topic writeable**

To make a mirror topic writable (i.e., change it from read-only, mirrored state to a regular, independent, writable topic) in Confluent Kafka (whether in Confluent Platform or Confluent Cloud with Cluster Linking), you need to use either the promote or failover command. This operation is commonly called “promoting” the mirror topic, and is an essential step in cutover, DR, or migration workflows.

> **Note:** Mirror topics are read-only topics created and owned by a cluster link. You cannot directly write to these topics; only the cluster link can synchronize data from the source topic. To make the topic writable, you must “convert” it to a regular topic by stopping (detaching) it from the cluster link. This is done by either promoting or failing over the topic. Once promoted or failed over, the mirror topic will permanently stop syncing from its source, and you can produce records to it like any other topic. This operation cannot be reversed—you would need to recreate the topic as a mirror topic if you want to re-establish mirroring.

Execute the following steps to make the mirror topic writable:

1. Confirm the current status of the mirror topic (and check that mirroring lag is zero if doing a planned migration).

```bash
confluent kafka mirror describe <mirror-topic-name> --link <link-name>
```

For promote, ensure network reachability between the destination and source clusters, and that lag is zero.

2. Promote the mirror topic.

```bash
confluent kafka mirror promote <mirror-topic-name> --link <link-name> --cluster <destination-cluster-id>
```

This will check lag, synchronize everything, and make the topic writable only if fully caught up.

> ⚠️ **Note:** 
>
> **Promote**: Use when both the source and destination clusters are healthy and there is no mirroring lag. The promote command guarantees that the mirror topic is fully caught up and all relevant metadata (including consumer offsets) is synchronized from source to mirror before making it writable. This is the recommended operation for planned cutovers or migrations. 
> 
> **Failover**: Use if the source cluster is unavailable or in disaster scenarios. The failover command will forcibly convert the mirror topic to a writable topic regardless of synchronization status (which may result in some data or offset lag).
Both commands must be executed on the destination cluster—the cluster hosting the mirror topic.

3. Validate that the topic is now writable by producing new records. For example, execute the following command:

```bash
kafka-console-producer.sh --bootstrap-server <confluent-cloud-kafka-broker>:9092 --topic <mirror-topic-name>
```

4. Check topic state. The topic state will be STOPPED when it is writable (no longer mirroring).

```bash
confluent kafka mirror describe <mirror-topic-name> --link <link-name>
```

<br>

## <a name="step-7"></a>**Step 7: Produce and Consume Data from Confluent Cloud**





  
   

<br>

> ⚠️ **Note:** Make sure to delete all the resources created if you no longer wish to use the environment.

## <a name="step-8"></a>**Confluent Resources and Further Testing**

* [Confluent Cloud Documentation](https://docs.confluent.io/cloud/current/overview.html)

* [Confluent Connectors](https://www.confluent.io/hub/) - A recommended next step after the workshop is to deploy a connector of your choice.

* [Confluent Cloud Schema Registry](https://docs.confluent.io/cloud/current/client-apps/schemas-manage.html#)

* [Best Practices for Developing Apache Kafka Applications on Confluent Cloud](https://assets.confluent.io/m/14397e757459a58d/original/20200205-WP-Best_Practices_for_Developing_Apache_Kafka_Applications_on_Confluent_Cloud.pdf) 

* [Confluent Cloud Demos and Examples](https://docs.confluent.io/platform/current/tutorials/examples/ccloud/docs/ccloud-demos-overview.html)

* [Kafka Connect Deep Dive – Error Handling and Dead Letter Queues](https://www.confluent.io/blog/kafka-connect-deep-dive-error-handling-dead-letter-queues/)
