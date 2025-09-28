package com.example.testingdeploy.command;


import lombok.RequiredArgsConstructor;
import org.springframework.shell.standard.ShellComponent;
import org.springframework.shell.standard.ShellMethod;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;

@ShellComponent
@RequiredArgsConstructor
public class DeployCommand {

    @ShellMethod("Deploy a Spring project from Git repo")
    public String deploy(String repoUrl, String branch) {
        StringBuilder output = new StringBuilder();
        try {
            ProcessBuilder builder = new ProcessBuilder("bash", "./deploy.sh", repoUrl, branch);
            builder.directory(new File(System.getProperty("user.dir")));
            Process process = builder.start();

            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            BufferedReader errorReader = new BufferedReader(new InputStreamReader(process.getErrorStream()));

            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
            }
            while ((line = errorReader.readLine()) != null) {
                output.append("ERROR: ").append(line).append("\n");
            }

            int exitCode = process.waitFor();
            if (exitCode != 0) {
                output.append("Deployment failed at above step.\n");
            }
        } catch (Exception e) {
            output.append("Exception: ").append(e.getMessage());
        }

        return output.toString();
    }
}

