package com.example.testingdeploy.command;

import com.example.testingdeploy.response.DeployResponse;
import com.jcraft.jsch.*;
import lombok.RequiredArgsConstructor;
import org.springframework.shell.standard.ShellComponent;
import org.springframework.shell.standard.ShellMethod;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

@ShellComponent
@RequiredArgsConstructor
public class DeployCommand {

    @ShellMethod("Deploy a Spring project remotely via SSH")
    public DeployResponse deploy(
            String repoUrl,
            String branch,
            String remoteIp,
            String username,
            String password
    ) {
        List<String> logs = new ArrayList<>();
        String remoteDir = "/home/" + username + "/deploy-spring-project/deploy-spring";

        try {
            JSch jsch = new JSch();
            Session session = jsch.getSession(username, remoteIp, 22);
            session.setPassword(password);
            session.setConfig("StrictHostKeyChecking", "no");
            session.connect();

            String command = "cd " + remoteDir + " && bash deploy.sh " + repoUrl + " " + branch;

            ChannelExec channel = (ChannelExec) session.openChannel("exec");
            channel.setCommand(command);
            channel.setErrStream(System.err);

            BufferedReader reader = new BufferedReader(new InputStreamReader(channel.getInputStream()));
            channel.connect();

            String line;
            while ((line = reader.readLine()) != null) {
                logs.add(line);
            }

            int exitStatus = channel.getExitStatus();
            boolean success = exitStatus == 0 &&
                    logs.stream().noneMatch(l -> l.startsWith("ERROR:") || l.contains("Deployment failed"));

            if (!success && !logs.contains("Deployment failed at above step.")) {
                logs.add("Deployment failed at above step.");
            }

            String message = success ? "Deployment succeeded!" : "Deployment failed!";

            channel.disconnect();
            session.disconnect();

            return new DeployResponse(success, message, logs);

        } catch (Exception e) {
            logs.add("Exception: " + e.getMessage());
            return new DeployResponse(false, "Deployment failed due to exception!", logs);
        }
    }
}
