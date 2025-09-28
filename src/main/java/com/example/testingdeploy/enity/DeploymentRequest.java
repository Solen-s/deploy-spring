package com.example.testingdeploy.enity;

import io.swagger.v3.oas.annotations.links.Link;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;

@Data
@RequiredArgsConstructor
@AllArgsConstructor
public class DeploymentRequest {
    @NotBlank(message = "Git repository URL is required")
    @Pattern(
            regexp = "^(https:\\/\\/|git@)[\\w.@:/\\-~]+\\.git$",
            message = "Invalid Git repository URL"
    )
    private String repoUrl;

    private String branch;

}
