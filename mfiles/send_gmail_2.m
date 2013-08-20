
function send_gmail(outgoing,subject,body)

% Modify these two lines to reflect your account and password.  Call the 
% command pcode('send_gmail.m') to generate a secure file, remove your
% credentials from the file, and remove it from the path.
%
% To enable email notifications in E3D, modify and uncomment lines 421 and
% 429 in e3d_main.m

myaddress = 'user@gmail.com';
mypassword = 'password';

if isempty(myaddress)
   display('Update outgoing email configuration in file "send_gmail.m"') 
    
else
    setpref('Internet','E_mail',myaddress);
    setpref('Internet','SMTP_Server','smtp.gmail.com');
    setpref('Internet','SMTP_Username',myaddress);
    setpref('Internet','SMTP_Password',mypassword);

    props = java.lang.System.getProperties;
    props.setProperty('mail.smtp.auth','true');
    props.setProperty('mail.smtp.socketFactory.class', ...
                      'javax.net.ssl.SSLSocketFactory');
    props.setProperty('mail.smtp.socketFactory.port','465');
    sendmail(outgoing, subject, body);
end

end