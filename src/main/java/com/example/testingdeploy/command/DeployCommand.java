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
            ProcessBuilder builder = new ProcessBuilder("bash", "./deploy.sh", repoUrl, branch);
            builder.directory(new File(System.getProperty("user.dir")));
            Process process = builder.start();

            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            BufferedReader errorReader = new BufferedReader(new InputStreamReader(process.getErrorStream()));

            String line;
            while ((line = reader.readLine()) != null) {
                logs.add(line);
            }
            while ((line = errorReader.readLine()) != null) {
                logs.add("ERROR: "+line);
            }

            int exitCode = process.waitFor();
            // Determine success
            boolean success = exitCode == 0 && logs.stream().noneMatch(l -> l.startsWith("ERROR:") || l.contains("Deployment failed"));
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


