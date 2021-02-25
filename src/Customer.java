/**
 * Created by: Anton Rolin
 * Date: 23/02/2021
 * Time: 18:08
 * Project: shoeshop_klient
 * Copyright: MIT
 */
public class Customer {

    private int id;
    private String location;
    private String firstName;
    private String lastName;
    private String userName;
    private String password;

    public Customer(int id, String firstName, String lastName, String location, String userName, String password){
        this.id = id;
        this.location = location;
        this.firstName = firstName;
        this.lastName = lastName;
        this.userName = userName;
        this.password = password;
    }

    public int getId() {
        return id;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public String getLocation() {
        return location;
    }

    public String getPassword() {
        return password;
    }
}
