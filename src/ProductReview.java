/**
 * Created by: Anton Rolin
 * Date: 23/02/2021
 * Time: 18:10
 * Project: shoeshop_klient
 * Copyright: MIT
 */
public class ProductReview {

    private Customer customer;
    private Product product;
    private String comment;
    private String gradeDescription;
    private int gradeValue;

    public ProductReview(Customer customer, Product product, String comment){
        this.customer = customer;
        this.product = product;
        this.comment = comment;
    }
}
