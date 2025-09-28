package com.example.testingdeploy.controller;

import com.example.testingdeploy.command.DeployCommand;
import com.example.testingdeploy.enity.DeploymentRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/deploy")
@RequiredArgsConstructor
public class DeployController {

    private final DeployCommand deployCommands;


    @PostMapping
    public ResponseEntity<String> deploy(@RequestBody DeploymentRequest request) {
        String repoUrl = request.getRepoUrl();
        String branch = request.getBranch();
        // use these values in your shell script

        // Call the deploy command (you can modify DeployCommand to accept branch too)
        String output = deployCommands.deploy(repoUrl,branch);

        return ResponseEntity.ok(output);
    }
}