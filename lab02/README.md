Lab two - APIs
====

## Part 1: Creating APIs

To expose a HTTP API endpoint, we first have to inject a Servlet into Camel context, go to **camel-context.xml** file under **Camel Contexts**, open the *source* tab, add the following code snippet before the `<camelContext..>` tag.

```
    ...
    <bean class="org.apache.camel.component.servlet.CamelHttpTransportServlet" id="camelHttpTransportServlet"/>
    <bean
        class="org.springframework.boot.web.servlet.ServletRegistrationBean" id="servlet">
        <property name="name" value="CamelServlet"/>
        <property name="servlet" ref="camelHttpTransportServlet"/>
        <property name="urlMappings" value="/myfuselab/*"/>
    </bean>
    ...
```

In the same file, under the `<camelcontext..>` tag add the following code snippet to configure the REST endpoint. So that it is now using the Servlet we have injected from last step

```
    ...
       <restConfiguration apiContextPath="api-docs" bindingMode="json"
            component="servlet" contextPath="/myfuselab">
            <apiProperty key="cors" value="true"/>
            <apiProperty key="api.title" value="My First Camel API Lab"/>
            <apiProperty key="api.version" value="1.0.0"/>
        </restConfiguration>
	<route id="customers">
    ...
```

We are now going to expose a single API endpoint, right after the **restConfiguration** add

```
    ...
        <rest path="/customer">
            <get uri="all">
            	<description>Retrieve all customer data</description>
                <to uri="direct:getallcustomer"/>
            </get>
        </rest>
    ...
```

Now, instead of trigger the database select with a timer, we are going to trigger it by the API call. In your Camel route, replace the **Timer** with **Direct** component.

replace

```
<from id="time1" uri="timer:timerName?repeatCount=1"/>
```

with

```
<from id="direct1" uri="direct:getallcustomer"/>
```

Next up, we are going to add all the dependencies needed to the maven **pom.xml** file

```
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
      <groupId>org.apache.camel</groupId>
      <artifactId>camel-servlet-starter</artifactId>
    </dependency>
    <dependency>
      <groupId>org.apache.camel</groupId>
      <artifactId>camel-jackson-starter</artifactId>
    </dependency>
    <dependency>
      <groupId>org.apache.camel</groupId>
      <artifactId>camel-swagger-java-starter</artifactId>
    </dependency>
```

Right click on the **myfuselab** in the project explorer panel, select **Run As..** -> **Maven build** to start up the Camel application again. And run the following command in your command line console.

```
curl -i http://localhost:8080/myfuselab/customer/all
```

Verify that it is returning a list of customer data in JSON format

```
[{"CUSTOMERID":"A01","VIPSTATUS":"Diamond","BALANCE":1000},{"CUSTOMERID":"A02","VIPSTATUS":"Gold","BALANCE":500}]
```

Stop the application, Try add another API endpoints which takes in the Customer ID and return the customer data matching the ID.

To display swagger documentation,

```
curl -i http://localhost:8080/myfuselab/api-docs
```

#### HINT!

* Add a new REST endpoint that takes in customerid and calls the new camel route we just created.
	* uri="{custid}"
* Add a new Camel route that takes in customerid as paramter
	* select * from customerdemo where customerID=:#custid

Verify with Swagger doc and test the API make sure it is returning customer A01's data in JSON format

```
curl -i http://localhost:8080/myfuselab/api-docs
curl -i http://localhost:8080/myfuselab/customer/A01
```

```
[{"CUSTOMERID":"A01","VIPSTATUS":"Diamond","BALANCE":1000}]
```

## Part 2: API Management

#### Connecting your Customers API to 3scale

In order to connect your Customers API to 3scale, you need to follow three simple steps:

1. Access your 3scale Admin Portal and set up your first plans and metrics and your first API keys.
1. Integrate your API with 3scale using the API gateway in the staging environment (for development only).
1. Map your API endpoints to 3scale methods and metrics.

#### Step 1: Define your API

Your 3scale Admin Portal (http://&lt;YOURDOMAIN&gt;-admin.3scale.net) provides access to a number of configuration features.

1. Login into the Admin Portal:

    ![01-login.png](./img/01-login.png)

1. The first page you will land is the API tab. From here we will create our API definition. Select the `Create Service` option.

    ![02-create-service.png](./img/02-create-service.png)

1. Fill in the information for your API. Name it `Customers API` and `customers` for the system name. Add your personal description.

    ![03-new-service.png](./img/03-new-service.png)

1. Select the **APIcast self-managed** Gateway deployment option.

    ![04-apicast.png](./img/04-apicast.png)

1. Keep the **API Key (user_key)** Authentication.

    ![05-authentication.png](./img/05-authentication.png)

1. Click on **Create Service**
1. Select your new API and click on **Configure Self-managed Gateway**

    ![06-configure-apicast.png](./img/06-configure-apicast.png)

1. Click on the **add the Base URL of your API and save the configuration** button
1. Fill in the information for accessing your API. The private Base URL is the camel servlet server IP and default port (8080). For the staging and production, we will use the same Base URL. For this lab, we are going to use the route from the APIcast Gateway deployed on Openshift.

    ![07-baseurl-configuration.png](./img/07-baseurl-configuration.png)

1. Click on the **Update the Staging Environment** to save the changes and thenk click on the **Back to Integration & Configuration** link.

    ![08-update-staging.png](./img/08-update-staging.png)

1. Success! Your 3scale access control layer will now only allow authenticated calls through to your backend API.

#### Step 2: Configure your API access policies with application plans

In the previous step, you ensured that only authenticated calls are allowed through to your API. Now you will apply policies to differentiate rate limits.

In 3scale terms, *applications* define the credentials to access your API. An application is always associated with one *application plan*, which determines the access policies. Applications are stored within *developer accounts* – in the basic 3scale plans only a single application is allowed, but in the higher plans multiple applications per account are allowed.

1. Let's create a new application plan for this example. In order to do this, navigate to the **Application Plans** tab and click on **Create Application Plan**.

    ![09-create-applicationplan.png](./img/09-create-applicationplan.png)

1. Fill in the information for the name of your plan. In the form that opens, specify the desired name – for example "limited" – and the system name. Then click on **Create Application Plan** button.

    ![10-name-plan.png](./img/10-name-plan.png)

    After the previous step, you should see the list of application plans.

1. Your plan is created, now you need you to publish it. Click on the `publish` link to made it public.

    ![11-publish-plan.png](./img/11-publish-plan.png)

1. To asociate the application plan with an application, navigate to the **Developers** tab and click on the `Developer` link.

    ![12-developers.png](./img/12-developers.png)

1. Click on the `1 Application` link to access this developer's applications.

    ![13-applications.png](./img/13-applications.png)

1. Now, create a new Application by clicking the **Create Application** button.

    ![14-create-application.png](./img/14-create-application.png)

1. Select the previously created application plan from the combobox and fill in the information for the application. Click on the **Create Application** to save your changes.

    ![15-new-application.png](./img/15-new-application.png)

1. In the next screen, you will be presented with the autogenerated user key that will be used to access your API.

    ![16-user-key.png](./img/16-user-key.png)


#### Step 3: Deploy APIcast using the OpenShift template


1. By default you are logged in as *developer* and can proceed to the next step.

    Otherwise login into OpenShift using the `oc login` command from the OpenShift Client tools you downloaded and installed in the previous step. The default login credentials are *username = "developer"* and *password = "developer"*:

    ```
    oc login https://<OPENSHIFT-SERVER-IP>:8443
    ```

    You should see Login successful. in the output.

2. Create your project. This example sets the display name as *gateway*

    ```
    oc new-project "3scalegateway" --display-name="gateway" --description="3scale gateway demo"
    ```

    The response should look like this:

    ```
    Now using project "3scalegateway" on server "https://172.30.0.112:8443".
    ```

    Ignore the suggested next steps in the text output at the command prompt and proceed to the next step below.

1. Create a new Secret to reference your project by replacing and with yours.

    ```
    oc secret new-basicauth apicast-configuration-url-secret --password=https://<ACCESS_TOKEN>@<DOMAIN>-admin.3scale.net
    ```

    Here &lt;ACCESS_TOKEN&gt; is an Access Token (not a Service Token) for the 3scale Account Management API, and &lt;DOMAIN&gt;-admin.3scale.net is the URL of your 3scale Admin Portal.

    The response should look like this:

    ```
    secret/apicast-configuration-url-secret
    ```

1. Create an application for your APIcast Gateway from the template, and start the deployment:

    ```
    oc new-app -f https://raw.githubusercontent.com/3scale/3scale-amp-openshift-templates/2.0.0.GA-redhat-2/apicast-gateway/apicast.yml
    ```

    You should see the following messages at the bottom of the output:

    ```
    --> Creating resources with label app=3scale-gateway ...
      deploymentconfig "apicast" created
      service "apicast" created
    --> Success
      Run 'oc status' to view your app.
    ```

1. Open the web console for your OpenShift cluster in your browser:  https://&lt;OPENSHIFT-SERVER-IP&gt;:8443/console/

    You should see the login screen:

    ![17-openshift-login.png](./img/17-openshift-login.png)

      > **Note:** You may receive a warning about an untrusted web-site. This is expected, as we are trying to access the web console through secure protocol, without having configured a valid certificate. While you should avoid this in production environment, for this test setup you can go ahead and create an exception for this address.

1. Log in using the `developer` credentials in the section above.

    You will see a list of projects, including the *gateway* project you created from the command line above.

    ![18-openshift-projects.png](./img/18-openshift-projects.png)

1. Click on *gateway* and you will see the *Overview* tab.

    Each APIcast instance, upon starting, downloads the required configuration from 3scale using the settings you provided on the **Integration** page of your 3scale Admin Portal.

    ![19-openshift-threescale.png](./img/19-openshift-threescale.png)

1. In order to allow your APIcast instances to receive traffic, you'll need to create a route. Start by clicking on **Create Route**.

    ![20-openshift-create-route.png](./img/20-openshift-create-route.png)

    Enter the same host you set in 3scale above in the section **Public Base URL** (without the http:// and without the port) , e.g. `gateway.openshift.demo`, then click the **Create** button.

    ![21-openshift-route-config.png](./img/21-openshift-route-config.png)

    Your API Gateways are now ready to receive traffic. OpenShift takes care of load-balancing incoming requests to the route across the two running APIcast instances.

    If you wish to see the APIcast logs, you can do so by clicking **Applications > Pods**, selecting one of the pods and finally selecting **Logs**.

#### Step 4: Test APIcast

1. Test that APIcast authorizes a valid call to your API, by executing a curl command with your valid *user_key* to the *hostname* that you configured in the previous step:

    ```
    curl -i "http://gateway.openshift.demo/?user_key=YOUR_USER_KEY" --insecure
    ```

2. Test that APIcast does not authorize an invalid call to your API.

    ```
    curl -i "http://gateway.openshift.demo/?user_key=INVALID_KEY" --insecure
    ```
