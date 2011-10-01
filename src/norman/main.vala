/* Copyright 2011 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution. 
 */

MainLoop? main_loop = null;
int ec = 0;
Geary.Credentials? credentials = null;
Geary.ComposedEmail? composed_email = null;

async void main_async() throws Error {
    Geary.Smtp.ClientSession session = new Geary.Smtp.ClientSession(Geary.GmailAccount.SMTP_ENDPOINT);
    
    Geary.Smtp.Greeting? greeting = yield session.login_async(credentials);
    stdout.printf("%s\n", greeting.to_string());
    
    Geary.RFC822.Message msg = new Geary.RFC822.Message.from_composed_email(composed_email);
    assert(msg.message != null);
    
    yield session.send_email_async(msg.message);
    stdout.printf("Sent\n");
    
    Geary.Smtp.Response? quit = yield session.quit_async();
    stdout.printf("%s\n", quit.to_string());
}

void on_main_completed(Object? object, AsyncResult result) {
    try {
        main_async.end(result);
    } catch (Error err) {
        stderr.printf("%s\n", err.message);
        ec = 1;
    }
    
    if (main_loop != null)
        main_loop.quit();
}

int main(string[] args) {
    if (args.length < 3 || Geary.String.is_empty(args[1]) || Geary.String.is_empty(args[2])) {
        stdout.printf("usage: norman <user> <pass>\n");
        
        return 1;
    }
    
    credentials = new Geary.Credentials(args[1], args[2]);
    
    stdout.printf("From (blank for \"%s\"): ", credentials.user);
    string? from = stdin.read_line();
    if (Geary.String.is_empty(from))
        from = credentials.user;
    
    stdout.printf("To: ");
    string? to = stdin.read_line();
    if (Geary.String.is_empty(to))
        return 1;
    
    stdout.printf("Subject: ");
    string? subject = stdin.read_line();
    
    stdout.printf("Type message, blank line to send, Ctrl+C to exit.\n");
    
    StringBuilder builder = new StringBuilder();
    for (;;) {
        string? line = stdin.read_line();
        if (Geary.String.is_empty(line))
            break;
        
        builder.append(line);
    }
    
    composed_email = new Geary.ComposedEmail(new DateTime.now_local(), from);
    composed_email.to = to;
    composed_email.subject = subject;
    composed_email.body = builder.str;
    
    main_loop = new MainLoop();
    
    main_async.begin(on_main_completed);
    
    stdout.printf("Sending...\n");
    
    main_loop.run();
    
    return ec;
}

