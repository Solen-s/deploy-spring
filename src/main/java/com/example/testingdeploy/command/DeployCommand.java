package com.example.testingdeploy.command;

import com.example.testingdeploy.response.DeployResponse;
import com.jcraft.jsch.*;
import lombok.RequiredArgsConstructor;
import org.springframework.shell.standard.ShellComponent;
import org.springframework.shell.standard.ShellMethod;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

@ShellComponent
@RequiredArgsConstructor
public class DeployCommand {

    @ShellMethod("Deploy a Spring project from Git repo via SSH")
    public DeployResponse deploy(
            String host,         // Remote server IP
            String username,     // SSH username
            String password,     // SSH password
            String repoUrl,      // Git repo URL
            String branch      // Branch to deploy
    ) {
        List<String> logs = new ArrayList<>();

        try {
            JSch jsch = new JSch();
            Session session = jsch.getSession(username, host, 22);
            session.setPassword(password);

            // Avoid host key check
            session.setConfig("StrictHostKeyChecking", "no");
            session.connect();

            // Command to run deploy.sh on remote server
            String command = String.format("/home/%s/deploy-spring/deploy.sh %s %s %s", username, repoUrl, branch, port);

            ChannelExec channel = (ChannelExec) session.openChannel("exec");
            channel.setCommand(command);
            channel.setErrStream(System.err);

            InputStream in = channel.getInputStream();
            channel.connect();

            // Read output in real-time
            byte[] tmp = new byte[1024];
            int read;
            while ((read = in.read(tmp)) != -1) {
                String line = new String(tmp, 0, read);
                logs.add(line);
                System.out.print(line);
            }

            channel.disconnect();
            session.disconnect();

            return new DeployResponse(true, "Deployment command executed on remote server", logs);

        } catch (Exception e) {
            logs.add("Exception: " + e.getMessage());
            return new DeployResponse(false, "Remote deployment failed", logs);
        }
    }
}
