const axios = require("axios");
const Product = require("./product.model");

async function seedFakeProducts() {
  const { data } = await axios.get("https://fakestoreapi.com/products");

  for (const p of data) {
    await Product.create({
      title: p.title,
      description: p.description,
      category: p.category,
      priceUsd: p.price,
      imageUrl: p.image,
      stock: Math.floor(Math.random() * 100) + 10,
    });
  }

  console.log("Fake products imported");
}

module.exports = seedFakeProducts;