const express = require("express");
const cors = require("cors");
require("dotenv").config();
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

const authRoutes = require("./Auth");
app.use("/api", authRoutes);

const productRoutes = require("./product");
app.use("/api", productRoutes);

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.listen(5000, () => {
  console.log("Server running on port 5000");
});
