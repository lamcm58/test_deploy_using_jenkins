<?php

/**
 * Setup environment file and generate APP_KEY if needed
 * This script runs after composer install/update
 */

// Step 1: Copy .env.example to .env if .env doesn't exist
if (!file_exists('.env') && file_exists('.env.example')) {
    copy('.env.example', '.env');
    echo ".env file created from .env.example\n";
}

// Step 2: Generate APP_KEY if it doesn't have a value
if (file_exists('.env')) {
    $envContent = file_get_contents('.env');
    
    // Check if APP_KEY exists and has a value
    $hasAppKey = preg_match('/^APP_KEY=(.+)$/m', $envContent, $matches);
    
    // If APP_KEY doesn't exist or is empty/null, generate it
    if (!$hasAppKey || empty(trim($matches[1])) || trim($matches[1]) === 'null' || trim($matches[1]) === '') {
        // Check if artisan exists before running
        if (file_exists('artisan')) {
            // Use Laravel's key:generate command
            exec('php artisan key:generate --ansi', $output, $returnVar);
            
            if ($returnVar === 0) {
                echo "APP_KEY generated successfully\n";
            } else {
                echo "Warning: Failed to generate APP_KEY. You may need to run 'php artisan key:generate' manually.\n";
            }
        } else {
            echo "Warning: artisan file not found. Skipping APP_KEY generation.\n";
        }
    } else {
        echo "APP_KEY already exists\n";
    }
} else {
    echo "Warning: .env file not found\n";
}

