<div align="center" padding=25px>
    <img src="images/confluent.png" width=50% height=50%>
</div>

# <div align="center">Data Migration from Apache Kafka to Confluent Cloud</div>
## <div align="center">Lab Guide</div>
<br>

## **Agenda**

1. [TBD](#step-1)
2. [TBD](#step-2)

***

## **Architecture**

<div align="center">
    <img src="images/architecture.png" width=75% height=75%>
</div>

*** 

## **Prerequisites**
<br>

1. Confluent Cloud Account
    - Sign-up for a Confluent Cloud account [here](https://www.confluent.io/confluent-cloud/tryfree/)
    - Once you have signed up and logged in, click on the menu icon at the upper right hand corner, click on "Billing & payment", then enter payment details under “Payment details & contacts”. A screenshot of the billing UI is included below.

    > **Note:** You will create resources during this workshop that will incur costs. When you sign up for a Confluent Cloud account, you will get free credits to use in Confluent Cloud. This will cover the cost of resources created during the workshop. More details on the specifics can be found [here](https://www.confluent.io/confluent-cloud/tryfree/).

***

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

TBD

## <a name="step-2"></a>**Step 2: Produce and Consume Data in OSK**

TBD

## <a name="step-3"></a>**Step 3: Set up Confluent Cloud and Create a Dedicated Cluster**

1. Log in to [Confluent Cloud](https://confluent.cloud) and enter your email and password.

<div align="center" padding=25px>
    <img src="images/login.png" width=50% height=50%>
</div>

2. If you are logging in for the first time, you will see a self-guided wizard that walks you through spinning up a cluster. Please minimize this as you will walk through those steps in this workshop. 


3. Click **+ Add Environment**. Specify an **Environment Name** and Click **Create**. 

    >**Note:** An environment contains clusters and its deployed components such as Connectors, ksqlDB, and Schema Registry. You have the ability to create different environments based on your company's requirements. Confluent has seen companies use environments to separate Development/Testing, Pre-Production, and Production clusters.
    
    >There is a *default* environment ready in your account upon account creation. You can use this *default* environment for the purpose of this workshop if you do not wish to create an additional environment.

<div align="center" padding=25px>
    <img src="images/environment.png" width=50% height=50%>
</div>

2. Now that you have an environment, click **Create Cluster**. 

    > **Note:** Confluent Cloud clusters are available in 3 types: Basic, Standard, and Dedicated. Basic is intended for development use cases so you will use that for the workshop. Basic clusters only support single zone availability. Standard and Dedicated clusters are intended for production use and support Multi-zone deployments. If you are interested in learning more about the different types of clusters and their associated features and limits, refer to this [documentation](https://docs.confluent.io/current/cloud/clusters/cluster-types.html).

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
   

## <a name="step-3"></a>**Step 3: Set up Cluster Linking**

To set up Cluster Linking in Confluent Cloud, follow these steps:

1. Log in to the Confluent Cloud Console and select **Cluster links** from the menu on the left.
2. Click **Create cluster link**.
3. In the Source Cluster configurations:
       3.1. jksjska
       3.2. jksdfhjks
3.1. hgjhghj
   	3.1. Select **Confluent Platform or Apache Kafka** as the Source Cluster.
   	3.2. Enter the source cluster Id (cluster id of your OSK).
   	3.3. Uncheck the **Source initiated connection** in the Security access section and provide the Bootstrap server URL of your OSK.
5. Select the destination cluster as the starting point.
In the wizard, specify the source cluster and environment.
Only clusters compatible for linking will appear.
If needed, provide API key and secret details for the source cluster.
The UI will guide you through configuring access options. You may need to specify credentials for a service account with the appropriate permissions.
Provide a link name and, if prompted, configure any other allowed options.
Review all selections and click Create.




  
    > **Note:** Make sure to delete all the resources created if you no longer wish to use the environment.



## <a name="step-9"></a>**Confluent Resources and Further Testing**

* [Confluent Cloud Documentation](https://docs.confluent.io/cloud/current/overview.html)

* [Confluent Connectors](https://www.confluent.io/hub/) - A recommended next step after the workshop is to deploy a connector of your choice.

* [Confluent Cloud Schema Registry](https://docs.confluent.io/cloud/current/client-apps/schemas-manage.html#)

* [Best Practices for Developing Apache Kafka Applications on Confluent Cloud](https://assets.confluent.io/m/14397e757459a58d/original/20200205-WP-Best_Practices_for_Developing_Apache_Kafka_Applications_on_Confluent_Cloud.pdf) 

* [Confluent Cloud Demos and Examples](https://docs.confluent.io/platform/current/tutorials/examples/ccloud/docs/ccloud-demos-overview.html)

* [Kafka Connect Deep Dive – Error Handling and Dead Letter Queues](https://www.confluent.io/blog/kafka-connect-deep-dive-error-handling-dead-letter-queues/)
