package com.example.testingdeploy.command;

import com.example.testingdeploy.response.DeployResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.shell.standard.ShellComponent;
import org.springframework.shell.standard.ShellMethod;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

@ShellComponent
@RequiredArgsConstructor
public class DeployCommand {

    @ShellMethod("Deploy a Spring project from Git repo")
    public DeployResponse deploy(String repoUrl, String branch) {
        List<String> logs = new ArrayList<>();
        try {
            // Absolute path to deploy.sh on host
            ProcessBuilder builder = new ProcessBuilder(
                    "/bin/bash",
                    "/app",
                    repoUrl,
                    branch
            );

            // Run on host, current working directory
            builder.directory(new File("/home/solen/deploy-spring-project"));
            builder.redirectErrorStream(true);
            builder.environment().put("PATH", "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin");

            Process process = builder.start();

            // Read output in real-time
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                logs.add(line);
                System.out.println(line);
            }

            int exitCode = process.waitFor();
            boolean success = exitCode == 0 && logs.stream().noneMatch(l -> l.contains("failed"));

            if (!success && !logs.contains("Deployment failed at above step.")) {
                logs.add("Deployment failed at above step.");
            }

            String message = success ? "Deployment succeeded!" : "Deployment failed!";
            return new DeployResponse(success, message, logs);

        } catch (Exception e) {
            logs.add("Exception: " + e.getMessage());
            return new DeployResponse(false, "Deployment failed due to exception!", logs);
        }
    }
}
