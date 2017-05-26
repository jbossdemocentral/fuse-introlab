## Lab two - Creating APIs

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

