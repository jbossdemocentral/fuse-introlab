## Lab three - Deploying to OpenShift

First, you will need to start your all-in-one OpenShift cluster.

1. Open a Terminal window

1. Issue the following command to check your internal IP address:

    ```
    ifconfig
    ```

    You will see an output like the following:

    ```
    enp0s25: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.17.7.57  netmask 255.255.0.0  broadcast 172.17.255.255
        inet6 fe80::3e97:eff:fe26:38ff  prefixlen 64  scopeid 0x20<link>
        ether 3c:97:0e:26:38:ff  txqueuelen 1000  (Ethernet)
        RX packets 409561  bytes 326113476 (311.0 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 396033  bytes 184335273 (175.7 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
        device interrupt 20  memory 0xd2500000-d2520000  

    lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1  (Local Loopback)
        RX packets 66641  bytes 24324856 (23.1 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 66641  bytes 24324856 (23.1 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

    ...
    ```
    **Note:** You will need to copy the information of the *inet* for the Ethernet connection that starts with **enpXXXX** and has the following pattern: **192.168.X.X** or **10.X.X.X**. If you have two Ethernet interfaces, use the one with the higher initial value.

    That will be your **OPENSHIFT-SERVER-IP** value to replace now on.

1. Start your OpenShift cluster with the following command:

    ```
    oc-cluster up agileintegration --public-hostname <OPENSHIFT-SERVER-IP> --routing-suffix=apps.<OPENSHIFT-SERVER-IP>.nip.io
    ```

    You will see an output like the following:

    ```
    # Using client for ocp v3.5.5.31
    [INFO] Created self signed certs. You can avoid self signed certificates warnings by trusting this certificate: /home/ec2-user/.oc/certs/master.server.crt
    [INFO] Running a previously created cluster
    oc cluster up --version v3.5.5.31 --image registry.access.redhat.com/openshift3/ose --public-hostname 127.0.0.1 --routing-suffix apps.127.0.0.1.nip.io --host-data-dir /home/ec2-user/.oc/profiles/test/data --host-config-dir /home/ec2-user/.oc/profiles/test/config --host-pv-dir /home/ec2-user/.oc/profiles/test/pv --use-existing-config -e TZ=EDT
    -- Checking OpenShift client ... OK
    -- Checking Docker client ... OK
    -- Checking Docker version ... OK
    -- Checking for existing OpenShift container ... OK
    -- Checking for registry.access.redhat.com/openshift3/ose:v3.5.5.31 image ... OK
    -- Checking Docker daemon configuration ... OK
    -- Checking for available ports ...
       WARNING: Binding DNS on port 8053 instead of 53, which may not be resolvable from all clients.
    -- Checking type of volume mount ...
       Using nsenter mounter for OpenShift volumes
    -- Creating host directories ... OK
    -- Finding server IP ...
       Using 172.31.28.24 as the server IP
    -- Starting OpenShift container ...
       Starting OpenShift using container 'origin'
       Waiting for API server to start listening
       OpenShift server started
    -- Removing temporary directory ... OK
    -- Checking container networking ... OK
    -- Server Information ...
       OpenShift server started.
       The server is accessible via web console at:
           https://192.168.42.100:8443

       You are logged in as:
           User:     developer
           Password: developer

       To login as administrator:
           oc login -u system:admin

    ...

    [INFO] Cluster created sucessfully
    Restarting openshift. Done
    ```

    Take notice of the developer user and password, you will use it later to login to the system. Also write down the web console URL address to login later on the lab.

    **Note:** If you need to stop your cluster at any time issue the `oc-cluster down agileintegration` command.

1. Add the `mysql-ephemeral` and `FIS` templates:

   FIS images
   ```
   oc create -f https://raw.githubusercontent.com/jboss-fuse/application-templates/master/fis-image-streams.json -n openshift --as=system:admin
   ```
   MYSQL Database
   ```
   oc create -f https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mysql-ephemeral-template.json -n openshift --as=system:admin
   ```

You can try view the OpenShift console by going to https://&lt;OPENSHIFT-SERVER-IP&gt;:8443/console in the browser. 

![00-openshift.png](./img/00-openshift.png)


Now it's time to deploy the application onto OpenShift, we have been testing with the H2 Database in memory, now it's time to run it with a real database. Add the following datasource setting under *src/main/resources* in **application.properties**

```
#mysql specific
mysql.service.name=mysql
mysql.service.database=sampledb
mysql.service.username=dbuser
mysql.service.password=password

#Database configuration
spring.datasource.url = jdbc:mysql://${${mysql.service.name}.service.host}:${${mysql.service.name}.service.port}/${mysql.service.database}
spring.datasource.username = ${mysql.service.username}
spring.datasource.password = ${mysql.service.password}
```

Since we will be using MYSQL database, add the driver dependency in **pom.xml**

```
<dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-jdbc</artifactId>
</dependency>
<dependency>
      <groupId>mysql</groupId>
      <artifactId>mysql-connector-java</artifactId>
      <scope>runtime</scope>
</dependency>
```


Open OpenShift Explorer view, on the top menu select window -> Show view -> others. a window will popup. Type openshift in the search field. And select OpenShift Explorer

![00-view.png](./img/00-view.png)

![00-openshiftexplorer02.png](./img/00-openshiftexplorer.png)

In OpenShift Explorer, right click on the connection that connects to current OpenShift, and create a new project. **NEW** -> **Project**

![01-newproject.png](./img/01-newproject.png)

**Note:** If you haven't created a connection previously:

1. Click on **New Connection Wizard...** to configure OpenShift. Enter your web console URL address (https://&lt;OPENSHIFT-SERVER-IP&gt;:8443) as the **Server** and click on the **retrieve** link to access the token.
1. In the popup window, log in as Developer using ID/PWD developer/developer.

    ![05-token.png](../img/05-token.png)

1. Click on **Close**
1. **UNCHECK** the *Save token* box and click Finish

    ![06-connection.png](../img/06-connection.png)

And create Project Name: **myfuseproject** with Display Name: **My Fuse Project**

![02-projectname.png](./img/02-projectname.png)

Inside the project we are going to first create a MYSQL database for our application. Right click on the new project name **myfuseproject** -> **New** -> **Application**

![03-newapp.png](./img/03-newapp.png)

Under Server application source, select **mysql-ephemeral(database, mysql) - openshift** and click next.

![04-mysql.png](./img/04-mysql.png)

Make sure to configure the following parameters

```
MYSQL_PASSWORD = password
MYSQL_ROOT_PASSWORD = password
MYSQL_USER = dbuser
```
![05-param.png](./img/05-param.png)

Click Finish, and you should see the mysql instance running in OpenShift explorer.

![06-mysqlcreated.png](./img/06-mysqlcreated.png)

Now we can finally push our application to OpenShift by right clicking on your project in project explorer. Select **Run As** -> **Run Configurations...**

![07-runmvn.png](./img/07-runmvn.png)

In the pop-up menu, select **Deploy myfuselab on OpenShift** on the left panel. Go to  **JRE** tab on the right, inside VM arguments, update kuberenets.master with your Openshift web console URL address **https://&lt;OPENSHIFT-SERVER-IP&gt;:8443** and kubernetes.namespace to **myfuseproject** and username/password to **developer/developer**. And **RUN**.

![08-runconfig.png](./img/08-runconfig.png)

To see everything running, in your browser, go to *https://&lt;OPENSHIFT-SERVER-IP&gt;:8443/console/* and login with **&lt;username&gt;/&lt;password&gt;** (for people using *oc cluster up or oc-cluster wrapper, it's developler/developer*). Select **My Fuse Project**. And you will see both application in the overview page.

![09-overview.png](./img/09-overview.png)

To access the service outside OpenShift, go to **Application** -> **Service** on the left menu, and click **camel-ose-springboot-xml** in the service page.

![10-service.png](./img/10-service.png)

Click on **Create route**.

![11-createroute.png](./img/11-createroute.png)

Don't change anything and hit Create.

Access the API endpoint by going to following URL

```
curl http://<YOUR_ROUTE>/myfuselab/customer/all
curl  http://<YOUR_ROUTE>/myfuselab/customer/A01
```

Verify that it is returning customer data in JSON format
```
[{"CUSTOMERID":"A01","VIPSTATUS":"Diamond","BALANCE":1000},{"CUSTOMERID":"A02","VIPSTATUS":"Gold","BALANCE":500}]

[{"CUSTOMERID":"A01","VIPSTATUS":"Diamond","BALANCE":1000}]
```
To see the Camel route in action, in your OpenShift console, go to **Application** -> **pod** and select the first **camel-ose-springboot-xml-1-xxxxx** pod.

![12-podlist.png](./img/12-podlist.png)

Click **Open Java Console**, and it's going to take you to the indiviual console that show how your Camel route is doing.

![13-pod.png](./img/13-pod.png)

Click on **Route Diagram** and hit the URL couple of times to see what happens.

![14-javaconsole.png](./img/14-javaconsole.png)

For those of you who want to see what is going on in database, login to the MYSQL database in your command line console.

```
oc project myfuseproject

oc get pods
NAME                                   READY     STATUS    RESTARTS   AGE
camel-ose-springboot-xml-s2i-1-build   1/1       Running   0          15s
mysql-1-xxxxx                          1/1       Running   0          2m

oc rsh mysql-1-xxxxx

sh-4.2$ mysql -udbuser -p sampledb
Enter password:

mysql> select * from customerdemo;
+------------+-----------+---------+
| customerID | vipStatus | balance |
+------------+-----------+---------+
| A01        | Diamond   |    1000 |
| A02        | Gold      |     500 |
+------------+-----------+---------+
2 rows in set (0.00 sec)
```
