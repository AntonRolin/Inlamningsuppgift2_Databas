import java.io.FileInputStream;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

/**
 * Created by: Anton Rolin
 * Date: 23/02/2021
 * Time: 18:08
 * Project: shoeshop_klient
 * Copyright: MIT
 */
public class Repository{

    private Connection con;

    public Repository(){
        setupDatabaseConnection();
    }

    private void setupDatabaseConnection(){
        try{
            Properties prop = new Properties();
            prop.load(new FileInputStream("src/ConnectionSettings.properties"));

            Class.forName("com.mysql.cj.jdbc.Driver");

                Connection con = DriverManager.getConnection(prop.getProperty("connectionString"),
                        prop.getProperty("name"),
                        prop.getProperty("password"));
                this.con = con;

        }catch (Exception e){
            e.printStackTrace();
        }
    }

    public Customer login(String username, String password){
        Customer c = null;
        int id = 0;
        String firstName = null;
        String lastName = null;
        String location = null;
        String user = null;
        String pass = null;
        try {
            PreparedStatement pStmt =
                    con.prepareStatement("SELECT * FROM kund WHERE användarnamn = ? AND lösenord = ?");
            pStmt.setString(1, username);
            pStmt.setString(2, password);
            ResultSet rs = pStmt.executeQuery();

            if (rs.next()) {
                id = rs.getInt("id");
                firstName = rs.getString("förnamn");
                lastName = rs.getString("efternamn");
                location = rs.getString("ort");
                user = rs.getString("användarnamn");
                pass = rs.getString("lösenord");

                c = new Customer(id, firstName, lastName, location, user, pass);
            }
            return c;

        }catch (SQLException e){
            System.out.println("STATE:"+e.getSQLState());
            System.out.println("ERROR CODE:"+e.getErrorCode());
            System.out.println("Error, could not login");
        }
        return null;

    }

    public List<Product> getAllProducts(){
        List<Product> products = new ArrayList<>();
        int id;
        String brand;
        int size;
        String color;
        double price;
        int inStock;
        try {
            Statement stmt = con.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT * FROM produkt");
            while(rs.next()){
                id = rs.getInt("id");
                brand = rs.getString("märke");
                size = rs.getInt("storlek");
                color = rs.getString("färg");
                price = rs.getDouble("pris");
                inStock = rs.getInt("antal");
                products.add(new Product(id, brand, size, color, price, inStock));
            }
            return products;

        }catch (SQLException e){
            System.out.println("STATE:"+e.getSQLState());
            System.out.println("ERROR CODE:"+e.getErrorCode());
            System.out.println("Error, could not get products from database");
        }
        return null;
    }

    public int addToCart(int customerID, int productID, int orderID){
        try{
            CallableStatement stmt = con.prepareCall("CALL AddToCart(?,?,?)");
            stmt.setInt(1, customerID);
            stmt.setInt(2, productID);
            stmt.registerOutParameter(3, Types.INTEGER);
            stmt.setInt(3, orderID);
            stmt.execute();
            return stmt.getInt(3);

        }catch (SQLException e){
            System.out.println("STATE:"+e.getSQLState());
            System.out.println("ERROR CODE:"+e.getErrorCode());
            System.out.println("Error, could not add item to cart");
        }
        return orderID;
    }

    public List<Grade> getAllGrades(){
        List<Grade> grades = new ArrayList<>();
        int id;
        String description;
        int value;
        try {
            Statement stmt = con.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT * FROM betyg");
            while(rs.next()){
                id = rs.getInt("id");
                description = rs.getString("beskrivning");
                value = rs.getInt("sifferbetyg");
                grades.add(new Grade(id, description, value));
            }
            return grades;

        }catch (SQLException e){
            System.out.println("STATE:"+e.getSQLState());
            System.out.println("ERROR CODE:"+e.getErrorCode());
            System.out.println("Error, could not get products from database");
        }
        return null;
    }

    public int getProductAverageRating(int productID){
        try{
            PreparedStatement pStmt =
                    con.prepareStatement("SELECT getAverageScore(?)");
            pStmt.setInt(1, productID);
            ResultSet rs = pStmt.executeQuery();
            if(rs.next()){
                int value = rs.getInt("getAverageScore("+productID+")");
                if(value != 0)
                    return value;
            }

        }catch (SQLException e){
            System.out.println("STATE:"+e.getSQLState());
            System.out.println("ERROR CODE:"+e.getErrorCode());
            System.out.println("Error, could not retrieve product rating");
        }
        System.out.println("No reviews for this product yet");
        return 0;
    }

    public List<String> getProductComments(int productID){
        List<String> comments = new ArrayList<>();
        String comment;
        try{
            PreparedStatement pStmt =
                    con.prepareStatement("SELECT kommentar FROM produktbetyg WHERE produktid = ?");
            pStmt.setInt(1, productID);
            ResultSet rs = pStmt.executeQuery();
            while(rs.next()){
                comment = rs.getString("kommentar");
                comments.add(comment);
            }
            return comments;

        }catch (SQLException e){
            System.out.println("STATE:"+e.getSQLState());
            System.out.println("ERROR CODE:"+e.getErrorCode());
            System.out.println("Error, could not retrieve product reviews");
        }
        return null;
    }

    public void rateProduct(int customerID, int productID,int gradeID, String comment){
        try{
            CallableStatement stmt = con.prepareCall("CALL Rate(?,?,?,?)");
            stmt.setInt(1, customerID);
            stmt.setInt(2, productID);
            stmt.setInt(3, gradeID);
            stmt.setString(4, comment);
            stmt.execute();

        }catch (SQLException e){
            System.out.println("STATE:"+e.getSQLState());
            System.out.println("ERROR CODE:"+e.getErrorCode());
            System.out.println("Error, could not rate product (probably duplicate review)");
        }
    }
}
