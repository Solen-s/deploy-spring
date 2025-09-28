package com.example.testingdeploy.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;

import java.util.List;

@Data
@RequiredArgsConstructor
@AllArgsConstructor
public class DeployResponse {
    private boolean success;
    private String message;
    private List<String> logs;
}
