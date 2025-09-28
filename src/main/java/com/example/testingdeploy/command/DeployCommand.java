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
            builder.redirectErrorStream(true);
            builder.environment().put("PATH", "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin");
            Process process = builder.start();

            // Read output in real time
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                logs.add(line);
                System.out.println(line); // optional: print to console in real-time
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


