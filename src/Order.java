import java.util.ArrayList;
import java.util.List;

/**
 * Created by: Anton Rolin
 * Date: 23/02/2021
 * Time: 18:09
 * Project: shoeshop_klient
 * Copyright: MIT
 */
public class Order {

    private int id = 0;
    private String date;
    private Customer customer;
    List<Product> products = new ArrayList<>();

    public Order(Customer customer){
        this.customer = customer;
    }

    public void addProduct(Product p){
        products.add(p);
    }

    public List<Product> getProducts() {
        return products;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }
}
