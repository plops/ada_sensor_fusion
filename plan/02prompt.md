# Sensor Fusion Project Planning Prompt

You are a planning AI tasked with designing a comprehensive project for implementing sensor fusion algorithms in Ada/SPARK with formal verification. The project involves collecting sensor data from mobile devices and processing them using provably correct methods.

## Project Context & Constraints

**Data Collection Method**: I will use the free version of Sensor Logger (tszheichoi.com/sensorlogger) which works on both iPhone and Android and can stream data to an HTTP server using 1-second batches.

**Target Devices (Phase 1)**:
- iPhone 11 (iOS)
- Samsung S10e (Android)

**Available Sensors**:
- Accelerometer
- Gravity (derived - use for validation only)
- Gyroscope  
- Orientation/Quaternion (derived - use for validation only)
- Magnetometer
- Barometer (relative altitude & pressure)
- Location (GPS)

**Key Requirements**:
- Use raw sensor data as much as possible
- Account for coordinate system differences between devices (documented in awesome-sensor-logger submodule)
- Multi-step implementation with compiled, working program and SPARK verification for each component at each step
- Focus on correctness through formal methods

## Available Resources

I have set up a git repository with the `awesome-sensor-logger` submodule. The collection script in `plan/01collect.sh` has created a consolidated documentation file with relevant information organized by importance.

## Your Task

Please analyze the provided documentation and create a detailed project plan.
Assume that the implementation will be performed by an AI with much less intelligence and context than you, so each step shall give the required information. If issues arise during implementation the implementation AI shall use the DeepWiki MCP to ask questions about dependencies. For this you have to create a dependencies.md file that lists dependencies and their github repositories (consisting of <github-organisation>/<project-name> so that the MCP can find them, because DeepWiki uses the same structure as github).

Some information like the time synchronization, estimation of the device dependent maximum sampling frequencies or the coordinate system transformations may require us to perform experiments, acquire sample data and its interpretation. Give clear instructions how to perform such data acquisition.

The plan shall address:

### 0. Dependencies
- Install modern versions of Ada compiler and SPARK tools using Alire
- Tell the implementation AI where to find the dependencies in the dependencies.md file

### 1. Data Processing Architecture
- Design HTTP server to receive 1-second batch data from Sensor Logger
- Parse and validate JSON sensor data format
- Handle coordinate system transformations between iOS and Android
- Implement timestamp synchronization for 1-second batches
- Design data structures for raw sensor readings

### 2. Ada/SPARK System Architecture
- Separate I/O layer (HTTP server) from provable SPARK components
- Design pure functional core for sensor fusion algorithms
- Plan formal verification strategy for each component
- Design interfaces between Ada I/O and SPARK fusion logic
- Identify which algorithms need SPARK verification

### 3. Sensor Fusion Implementation Strategy
- **Step 1**: Basic data reception and validation (Ada only, no fusion)
- **Step 2**: Single-device sensor fusion (accelerometer + gyroscope + magnetometer)
- **Step 3**: Add coordinate system corrections and validation
- **Step 4**: Multi-device fusion (iPhone + Samsung data)
- **Step 5**: Advanced fusion with GPS/barometer integration

For each step: implement core fusion algorithms, prove correctness with SPARK, validate against derived sensors (gravity, orientation). Format the code using gnatformat (and perform other housekeeping you deem necessary) and commit the changes.

### 4. Formal Verification Plan
- Identify safety-critical properties to prove (no overflow, bounded errors, etc.)
- Plan SPARK verification for fusion mathematics
- Design test cases for verification
- Plan proof strategies for each algorithmic component

### 5. Development Milestones
- Each step must produce a compiled, working program
- SPARK verification must pass for each component
- Validation against derived sensors at each step
- Performance benchmarks for real-time processing (optional)

## Expected Output

Please provide:
1. A detailed technical architecture document
2. A step-by-step implementation plan with the 5 specified steps
3. Specific recommendations for Ada/SPARK libraries and tools
4. Code structure and module organization for formal verification
5. Testing and validation strategies using derived sensors
6. SPARK verification approach for each component
7. Performance requirements for 1-second batch processing

## Documentation Reference

The consolidated documentation file contains relevant information from the awesome-sensor-logger submodule, organized by:
- Sensor Logger app documentation (most relevant)
- Coordinate system differences between devices
- iOS and Android sensor specifics
- HTTP streaming protocols
- Sensor fusion algorithms and mathematics

Use this information to inform your technical decisions and implementation strategy.
