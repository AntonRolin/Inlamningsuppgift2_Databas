import java.util.List;

/**
 * Created by: Anton Rolin
 * Date: 23/02/2021
 * Time: 18:08
 * Project: shoeshop_klient
 * Copyright: MIT
 */
public class Product {

    private int id;
    private int size;
    private String color;
    private double price;
    private String brand;
    private int inStock;
    private List<String> categories;

    public Product(int id, String brand, int size, String color, double price, int inStock){
        this.id = id;
        this.size = size;
        this.color = color;
        this.price = price;
        this.brand = brand;
        this.inStock = inStock;
    }

    public String getBrand() {
        return brand;
    }

    public String getColor() {
        return color;
    }

    public int getSize() {
        return size;
    }

    public int getInStock() {
        return inStock;
    }

    public double getPrice() {
        return price;
    }

    public int getId() {
        return id;
    }
}
