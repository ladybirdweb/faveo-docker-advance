Provide executable permission to faveo-run.sh

chmod +x faveo-run.sh

Run the script faveo-run.sh with sudo privilege by passing the necessary arguments.

Note: You should have a Valid domain name pointing to your public IP. Since this domainname is used to obtain SSL Certificates from Let's Encrypt CA and the Email is used for the same process.
      The license code and Order Number can be obtained from your Faveo Helpdesk Billing portal, make sure not to include the '#' character from Order Number. 

Usage:

	sudo ./faveo-run.sh -domainname <your domainname> -email <example@email.com> -license <faveo license code> -orderno <faveo order number>

Example: It should look something like this.

      sudo ./faveo-run.sh -domainname berserker.tk -email berserkertest@gmail.com -license 5HINJHDGDIBK0000 -orderno 85070569

After the docker installtion completed you will be prompted with Database Credentials please copy and save them somewhere safe.

Now in the probe page while visiting your Faveo Helpdesk site in browser accept the license agreement and input the Database details which you copied in previously. Enter the license when asked and create the first Helpdesk user.

There is one final step needs to be done in order complete the installation. You have to edit the .env file which is generated in the Faveo root directory after completing the probe tests. Navigate to the faveo-docker directory here you will find the directory "faveo" which is downloaded by running the script and contains the Helpdesk files, inside it you need to edit the ".env" file and update the "Redis Host" value to "redis" by default it will be pointing to loopback address "127.0.0.1" here redis is the DNS name of redis container which will be resolved by the docker daemon.

