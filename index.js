const express = require('express');
const jwt = require('jsonwebtoken');
const app = express();
const port = 3003;

app.use(express.json());

const users = [
    {
        id: 1,
        username: 'Pedro',
        password: 'pipe*' // hashed password
    },
    {
        id: 2,
        username: 'Felipe',
        password: 'felipe*' // hashed password
    }
];

const secretKey = 'sdfcghbiuo;7t4#@$#%&^&^%$&%^#%@2wrghgdfs';

app.post('/login', (req, res) => {
    const { username, password } = req.body;
    const user = users.find(user => user.username === username && user.password === password);

    if (!user) {
        return res.status(401).send('Credenciales Invalidas!');
    }
    const token = jwt.sign({ userId: user.id }, secretKey);

    res.send({ token });
});

app.listen(port,()=>{
    console.log('El servidor esta corriendo en el puerto: ',port);
});

app.get('/protected', (req, res) => {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
        return res.status(401).send('No Header');
    }

    const token = authHeader.split(' ')[1];

    jwt.verify(token, secretKey, (err, payload) => {
        if (err) {
            return res.status(401).send('Token Invalido');
        }

        res.send({ message: 'This is protected data', userId: payload.userId });
    });
});

