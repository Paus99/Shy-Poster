import processing.video.*;

Capture video;
PImage prevFrame; // Store the previous video frame for motion detection
boolean motionDetected = false; // Flag to hide cubes when motion is detected

int numCubes = 50; // Number of cubes
Cube[] cubes;       // Array of Cube objects

float camRadius = 800; // Radius of the camera's circular path
float camAngle = 0;    // Angle for the camera's rotation
float camSpeed = 0.05; // Speed of the camera's rotation

// Adjustable thresholds for motion detection
float diffThreshold = 20; // Brightness difference threshold
int motionPixelThreshold = 100; // Number of motion pixels to trigger detection

PImage overlayImage; // The PNG overlay

void setup() {
  size(800, 1000, P3D); // 3D canvas
  overlayImage = loadImage("KERET.png"); // Load the PNG

  // Setup video capture
  video = new Capture(this, 320, 240);
  video.start();

  // Create floating cubes
  cubes = new Cube[numCubes];
  for (int i = 0; i < numCubes; i++) {
    cubes[i] = new Cube(
      random(-400, 400), random(-300, 300), random(-500, 500), // Scattered positions
      random(20, 80), color(random(255), random(255), random(255))
    );
  }
}

void draw() {
  background(0);

  // Debugging: Show the video feed in the corner
  image(video, 0, 0, 1, 1);

  // Check for motion
  if (video.available()) {
    video.read();
    motionDetected = detectMotion(video);
  }

  // Update camera position based on motion detection
  if (!motionDetected) {
    camSpeed = 0.05; // Resume camera rotation
    camAngle += camSpeed;
  } else {
    camSpeed = 0; // Stop camera rotation
  }

  float camX = camRadius * cos(camAngle);
  float camZ = camRadius * sin(camAngle);
  camera(camX, 0, camZ, 0, 0, 0, 0, 1, 0); // Rotate around the center

  if (!motionDetected) {
    // Draw cubes when no motion is detected
    for (Cube c : cubes) {
      c.update();
      c.display();
    }
  } else {
    // Display "I SEE YOU" as a 2D text overlay
    hint(DISABLE_DEPTH_TEST); // Disable depth testing
    camera();                 // Reset to default 2D camera
    fill(255, 255, 255);
    textSize(50);
    textAlign(CENTER, CENTER);
    text("I SEE YOU", width / 2, height / 2);
    hint(ENABLE_DEPTH_TEST);  // Re-enable depth testing
  }

  // Always render the PNG at the end
  hint(DISABLE_DEPTH_TEST);  // Disable depth testing to ensure the image draws on top
  camera();                  // Reset the camera to default 2D view
  imageMode(CENTER);         // Center the image
  image(overlayImage, width / 2, height / 2, overlayImage.width, overlayImage.height); // Adjust size if needed
  hint(ENABLE_DEPTH_TEST);   // Re-enable depth testing for subsequent 3D rendering
}

// Motion detection algorithm with debugging
boolean detectMotion(Capture currentFrame) {
  currentFrame.loadPixels();

  if (prevFrame == null) {
    prevFrame = currentFrame.get();
    println("Initializing prevFrame.");
    return false;
  }

  prevFrame.loadPixels();

  int motionCount = 0;
  for (int i = 0; i < currentFrame.pixels.length; i++) {
    color current = currentFrame.pixels[i];
    color previous = prevFrame.pixels[i];

    // Compare brightness values
    float diff = abs(brightness(current) - brightness(previous));
    if (diff > diffThreshold) { // Adjustable brightness threshold
      motionCount++;
    }
  }

  // Debugging: Print motion pixel count
  println("Motion pixels detected: " + motionCount);

  prevFrame = currentFrame.get();
  
  // Return true if motion is detected in a significant number of pixels
  return motionCount > motionPixelThreshold;
}

// Cube class
class Cube {
  float x, y, z;    // Position
  float size;       // Size of the cube
  int col;          // Color
  float angleX, angleY, angleZ; // Rotation angles
  float speedX, speedY, speedZ; // Rotation speeds
  float velX, velY, velZ;       // Velocity for floating

  Cube(float x, float y, float z, float size, int col) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.size = size;
    this.col = col;
    this.angleX = random(TWO_PI);
    this.angleY = random(TWO_PI);
    this.angleZ = random(TWO_PI);
    this.speedX = random(0.01, 0.05);
    this.speedY = random(0.01, 0.05);
    this.speedZ = random(0.01, 0.05);
    this.velX = random(-1, 1);
    this.velY = random(-1, 1);
    this.velZ = random(-1, 1);
  }

  void update() {
    // Update rotation angles
    angleX += speedX;
    angleY += speedY;
    angleZ += speedZ;

    // Update position
    x += velX;
    y += velY;
    z += velZ;

    // Bounce off the edges of the 3D space
    if (x > 400 || x < -400) velX *= -1;
    if (y > 300 || y < -300) velY *= -1;
    if (z > 500 || z < -500) velZ *= -1;
  }

  void display() {
    pushMatrix();
    translate(x, y, z); // Position the cube
    rotateX(angleX);    // Rotate around X-axis
    rotateY(angleY);    // Rotate around Y-axis
    rotateZ(angleZ);    // Rotate around Z-axis
    fill(col);
    stroke(255);        // Add a white stroke
    strokeWeight(2);    // Set stroke thickness
    box(size);          // Draw the cube
    popMatrix();
  }
}
