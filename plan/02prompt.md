# Sensor Fusion Project Planning Prompt

You are a planning AI tasked with designing a comprehensive learning project for implementing sensor fusion algorithms in Ada/SPARK. The project involves collecting sensor data from multiple mobile devices and processing them using formal methods.

## Project Context

I have the following mobile devices available:
- iPhone 11 (iOS)
- Samsung S10e (Android)
- Samsung A54 (Android)
- Xiaomi Mi4C (Android)  
- Realme C11 2021 (Android)

The goal is to create an Ada/SPARK program that performs sensor fusion using data from the internal sensors (accelerometer, gyroscope, magnetometer) of these devices, potentially combining data from multiple devices simultaneously.

## Available Resources

I have set up a git repository with the `awesome-sensor-logger` submodule which contains comprehensive information about sensor logging apps and libraries for different platforms. The collection script in `plan/01collect.sh` has gathered relevant documentation into `plan/collected_docs/`.

## Your Task

Please analyze the collected documentation and create a detailed project plan that addresses:

### 1. Data Collection Strategy
- Recommend the best sensor streaming apps for each device platform
- Identify optimal network protocols (UDP, TCP, MQTT, etc.) for real-time sensor fusion
- Design data format standards for cross-device compatibility
- Plan timestamp synchronization across multiple devices

### 2. Ada/SPARK Architecture
- Design the overall system architecture separating I/O from provable components
- Plan the networking layer for receiving sensor data
- Design data structures for sensor readings and fusion states
- Identify which components should be implemented in SPARK for formal verification

### 3. Sensor Fusion Implementation
- Recommend specific fusion algorithms to implement (Kalman filters, complementary filters, etc.)
- Plan the mathematical foundations and matrix operations needed
- Design testing strategies for fusion accuracy
- Plan multi-device data fusion algorithms

### 4. Development Phases
- Break the project into manageable learning milestones
- Identify prerequisites and dependencies
- Estimate development time for each phase
- Plan validation and testing approaches

### 5. Learning Objectives
- Define what will be learned about sensor fusion theory
- Identify Ada/SPARK programming concepts to master
- Plan formal verification and proof techniques
- Design experiments for understanding fusion behavior

## Expected Output

Please provide:
1. A detailed technical architecture document
2. A step-by-step implementation plan with phases
3. Specific recommendations for tools and libraries
4. Code structure and module organization
5. Testing and validation strategies
6. Learning milestones and success criteria

## Constraints and Considerations
- Must use Ada/SPARK for the core fusion logic
- Should support real-time processing with minimal latency
- Must handle multi-device synchronization challenges
- Should be designed for learning and experimentation
- Consider formal verification where applicable

Please analyze the collected documentation and provide a comprehensive project plan that will guide the implementation of this sensor fusion learning project.
