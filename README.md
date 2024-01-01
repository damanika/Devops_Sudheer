- name : Deploying war pack
  hosts : PROD
  become : yes
  vars : 
   USERNAME : tom_uesr
   TOM_PATH : /tom
   TOM_URL : https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.84/bin/apache-tomcat-9.0.84.tar.gz
   DEST_WAR : /tom/apache-tomcat-*/webapps/Vehicles_Hub.war
   
  tasks :
  
   - name : Create Tom User
     ansible.builtin.user:
        name : "{{USERNAME}}"

   - name : Create DIR for Tomcat
     file :
      path : "{{TOM_PATH}}"
      owner : "{{USERNAME}}"
      group : "{{USERNAME}}"
      state : directory
      mode : 0775

   - name : Downloading Tom Tar file
     ansible.builtin.archive :
      src : "{{TOM_URL}}"
      dest : "{{TOM_PATH}}"
      remote_src : yes
     become_user : "{{USERNAME}}"
     
   - name : Remove old directories
     shell : rm -rf *;
     args :
      chdir : "/tom/apache-tomcat-*/webapps"
     
   - name : Downlaod Java Package
     yum :
       name : java
       state : latest
       
   - name : Downlaod the artifact
     get_url :
       url : "{{WARPACK}}"
       dest : "{{DEST_WAR}}"
       
   - name : Starting Tomcat Validation
     shell : ps -ef | grep tomcat | grep -v grep
       register : tomcat
       ignore_errors : True
       
   - name : Start Tomcat if needed
     shell : "nohup sh /tom/apache-tomcat-*/bin/startup.sh"
       when : tomcat.rc != 0
