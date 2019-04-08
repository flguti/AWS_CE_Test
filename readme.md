## Flavio Lopes - Onica CE Test 

##Multiple Website Hosting

#OBJECTIVE

Launch a simple web server in a load balanced and highly available manner utilizing automation
and AWS best practices. This web server should be able to serve two different websites.

#DELIVERABLES

A single file template for either CloudFormation or Terraform which achieves the requirements
listed below. 
Template file (or URL to the template) should be emailed back to the Onica point of
contact by the set deadline.

#REQUIREMENTS

Create a single file template which accomplishes the following:

    • Create a VPC with private / public subnets and all required dependent infrastructure.
    • Create an ELB to be used to register web server instances.
    • Auto Scaling Group and Launch Configuration that launches EC2 instances and registers
    them to the ELB.
    • Security Group allowing HTTP traffic to load balancer from anywhere (not directly to the
    instances).
    • Security Group allowing only HTTP traffic from the load balancer to the instances.
    • Some kind of automation or scripting that achieves the following:
        • Install and configure webserver
        • Webserver must handle two different domains:
            • www.test.com must respond with ‘hello test’
            • ww2.test.com must respond with ‘hello test2’

AMI to be used must be ‘standard’ AWS AMIs. Acceptable AMIs to use (us-west-2):

    • ami-e251209a – Amazon Linux
    • ami-db710fa3 – Ubuntu
    • ami-3703414f – Windows 2016 Base

Equivalent AMI’s may be used in other regions if your project is region specific.


#SUCCESS CRITERIA

The final test will be running these two curl commands:
    curl -H "Host: www.test.com" http://name-of-elb-endpoint-here
    curl -H "Host: ww2.test.com" http://name-of-elb-endpoint-here
Those two commands should spit out 'hello test' and 'hello test2' respectively.

If the servers are terminated, the autoscaling group should replace them and configure them
appropriately without any interaction.

##POINTS OF DECISION
#TEMPLATE FILE

The file was created using Terraform, there was no utilization of modules, variable files or any other extra configuration tools due to the request of a single file to complete the requirements.

#REGARDING REQUIREMENTS

There was no code created to create EC2 instances, since the requirements included creation of a Launch Configuration and Auto Scaling Group, generation code for EC2 creation would only duplicate the code.
For the Linux OS it was chosen Amazon Linux, the AMI mentioned above was not located, the utilized option was the most udated standard Version provided by Amazon "ami-03338e1f67dae0168".



