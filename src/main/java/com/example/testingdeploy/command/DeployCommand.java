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

    @ShellMethod("Deploy a Spring project from Git repo via SSH with dynamic port")
    public DeployResponse deploy(
            String host,         // Remote server IP
            String username,     // SSH username
            String password,     // SSH password
            String repoUrl,      // Git repo URL
            String branch,       // Branch to deploy
            String port          // Dynamic port for the app
    ) {
        List<String> logs = new ArrayList<>();

        try {
            JSch jsch = new JSch();
            Session session = jsch.getSession(username, host, 22);
            session.setPassword(password);

            // Avoid host key check
            session.setConfig("StrictHostKeyChecking", "no");
            session.connect();

            // Correct command: deploy.sh with repo, branch, and port
            String command = String.format(
                    "/home/%s/deploy-spring-project/deploy-spring/deploy.sh '%s' '%s' '%s'",
                    username, repoUrl, branch, port
            );

            ChannelExec channel = (ChannelExec) session.openChannel("exec");
            channel.setCommand(command);

            InputStream in = channel.getInputStream();
            InputStream err = channel.getErrStream(); // capture stderr too

            channel.connect();

            byte[] tmp = new byte[1024];
            while (true) {
                while (in.available() > 0) {
                    int i = in.read(tmp, 0, 1024);
                    if (i < 0) break;
                    String line = new String(tmp, 0, i).replaceAll("\\r|\\n", ""); // ✅ remove newlines
                    logs.add(line);
                    System.out.print(line);
                }
                while (err.available() > 0) {
                    int i = err.read(tmp, 0, 1024);
                    if (i < 0) break;
                    String line = new String(tmp, 0, i).replaceAll("\\r|\\n", ""); // ✅ remove newlines
                    logs.add("[ERR] " + line);
                    System.err.print(line);
                }
                if (channel.isClosed()) {
                    if (in.available() > 0 || err.available() > 0) continue;
                    break;
                }
                Thread.sleep(100);
            }

            int exitStatus = channel.getExitStatus();
            logs.add("Exit status: " + exitStatus);

            channel.disconnect();
            session.disconnect();

            boolean success = exitStatus == 0;
            return new DeployResponse(success, success ? "Deployment succeeded!" : "Deployment failed!", logs);

        } catch (Exception e) {
            logs.add("Exception: " + e.getMessage());
            return new DeployResponse(false, "Remote deployment failed", logs);
        }
    }
}
