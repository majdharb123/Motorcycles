const express = require("express");
const cors = require("cors");
const path = require("path");

require("dotenv").config();

const app = express();

app.use(cors());
app.use(express.json());

// Authentication routes
const authRoutes = require("./Auth");
app.use("/api", authRoutes);

// Product routes
const productRoutes = require("./product");
app.use("/api", productRoutes);

// Uploaded images
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Root endpoint
app.get("/", (req, res) => {
  res.status(200).json({
    message: "Motorcycles API is running",
  });
});

// Unknown routes
app.use((req, res) => {
  res.status(404).json({
    message: "Route not found",
  });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});