
USE `meli-ae`

/*
Tarefa 1: Usuários que fazem aniversário hoje com +1500 vendas em jan/2020
*/

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.birth_date,
    c.customer_email
FROM Customer c
WHERE 
    -- Verifica se o aniversário é hoje
    MONTH(c.birth_date) = MONTH(CURRENT_DATE) 
    AND DAY(c.birth_date) = DAY(CURRENT_DATE)
    -- Filtra apenas vendedores
    AND c.is_seller = TRUE
    -- Subquery para contar vendas em janeiro de 2020
    AND (
        SELECT COUNT(s.sale_id)
        FROM Sale s
        INNER JOIN Post p ON s.post_id = p.post_id
        WHERE 
            p.seller_id = c.customer_id
            AND s.sale_date BETWEEN '2020-01-01' AND '2020-01-31'
            AND s.sale_status = 'completed' -- Considera apenas vendas concluídas
    ) > 1500; -- No teste, joguei para 5 para lidar com poucos dados sintéticos


/*
Tarefa 2: Top 5 vendedores por mês na categoria Celulares em 2020
*/

WITH sales_data AS (
    SELECT 
        p.seller_id,
        s.sale_total,
        c.category_name,
        MONTH(s.sale_date) AS sale_month
    FROM Sale s
    INNER JOIN Post p ON s.post_id = p.post_id
    INNER JOIN Product pr ON p.product_id = pr.product_id
    INNER JOIN Category c ON pr.category_id = c.category_id
    WHERE c.category_name = 'Smartphones Android'
        AND YEAR(s.sale_date) = 2020
        AND s.sale_status = 'completed'
),
ranked_sellers AS (
    SELECT
        sale_month,
        seller_id,
        SUM(sale_total) AS total_sales,
        ROW_NUMBER() OVER (
            PARTITION BY sale_month 
            ORDER BY SUM(sale_total) DESC
        ) AS rank_position
    FROM sales_data
    GROUP BY sale_month, seller_id
)
SELECT 
    sale_month AS mes,
    rank_position AS posicao,
    seller_id AS vendedor_id,
    total_sales AS total_vendido
FROM ranked_sellers
WHERE rank_position <= 5
ORDER BY sale_month, rank_position;


/*
-- Tarefa 3: Tabela de histórico e Stored Procedure

Estou pegando de Post porque nao vejo sentido em pegar o valor de um Produto generico, 
visto que cada item pode ter um valor diferente dependendo do vendedor.

Penso que so faria sentido pegar o preço de Product, por exemplo, caso seja necessario um 
preço padrao para todos os itens (mas daí é possivel alterar fazendo Joins; nao compensa ter arquitetura diferente)

*/

DELIMITER //

CREATE PROCEDURE GenerateDailyItemHistory(IN target_date DATE)
BEGIN
    -- Define a data alvo como a data atual caso não seja fornecida
    IF target_date IS NULL THEN
        SET target_date = CURDATE();
    END IF;

    -- Insere ou atualiza registros na ItemHistory para cada Post
    INSERT INTO ItemHistory (post_id, snapshot_date, post_price, post_status, recorded_at)
    SELECT 
        post_id, 
        target_date, 
        post_price, 
        post_status, 
        CURRENT_TIMESTAMP
    FROM Post
    ON DUPLICATE KEY UPDATE
        post_price = VALUES(post_price),
        post_status = VALUES(post_status),
        recorded_at = VALUES(recorded_at);
END //

DELIMITER ;

-- CALL GenerateDailyItemHistory('2020-01-02');