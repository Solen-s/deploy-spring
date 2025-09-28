package com.example.testingdeploy.controller;

import com.example.testingdeploy.command.DeployCommand;
import com.example.testingdeploy.enity.DeploymentRequest;
import com.example.testingdeploy.response.DeployResponse;
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
    public ResponseEntity<DeployResponse> deploy(@RequestBody DeploymentRequest request) {
        // Call the deploy command (you can modify DeployCommand to accept branch too)
        DeployResponse response = deployCommands.deploy(request.getRepoUrl(), request.getBranch());

        return ResponseEntity.ok(response);
    }
}