/**
 * Created by: Anton Rolin
 * Date: 25/02/2021
 * Time: 02:06
 * Project: shoeshop_klient
 * Copyright: MIT
 */
public class Grade {
    private int id;
    private String description;
    private int value;

    public Grade(int id, String description, int value){
        this.id = id;
        this.description = description;
        this.value = value;
    }

    public int getId() {
        return id;
    }

    public int getValue() {
        return value;
    }

    public String getDescription() {
        return description;
    }
}
